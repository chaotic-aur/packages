#!/usr/bin/env bash
# deps: aria2 getoptions trash-cli

VERSION="0.0.5"

if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  ecbo "Do not run as root user."
  exit 1
fi

## config file
_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/chaotic/chaotic.sh.conf"

if [ ! -f "$_config_file" ]; then
  install -Dm644 /dev/stdin "$_config_file" << END
_script_dir=\$(dirname \$(readlink -f \$0))

_output_dir="/tmp"
_working_dir="/tmp"

_build_dir_remote="build"

_user="\$USER"

_filter_list=(
  # required
  -e 's@[#: ].*\$@@'

  # false pos
  -e 's@^linux-.*-x64v[234](-\S+*)?\$@@'
  -e 's@^linux-znver[234](-\S+*)?\$@@'

  # custom
  -e 's@^(chaotic|garuda)-.*\$@@'

  # extra
  -e '/^\s*\$/d' # remove blank lines
)
END
fi

source "$_config_file"

parser_definition() {
  setup REST help:usage -- "Usage: $(basename $0) [options]... [INPUT]" ''
  msg -- 'Options:'
  flag ADD -a --add -- "[package-list] - add or update packages"
  flag BUMP -b --bump -- "[package-list] - bump pkgrel of packages"
  flag DROP -d --drop -- "[package-list] - drop packages"

  flag TRIGGER_REBUILD --trigger-rebuild --tr -- "[trigger-package] [package-list] - add rebuild trigger to packages"
  flag TRIGGER_PIPELINE --trigger-pipeline --tp -- "[trigger-name] [package-list] - add pipeline trigger to packages"

  flag COMMIT --commit -- "[package-list] - commit packages"
  param MSG --msg -- "commit message"
  flag EDIT -e --edit -- "edit config/info of packages"
  param ISSUE -n --issue -- "github issue number"

  flag CHECKSYNC --check-sync --cs -- "[package-list] - check package sync with aur"

  flag CHECK -c --check -- "create lists of broken/missing *packages*"
  flag CHECKBASE --check-base -- "create list of broken/missing *pkgbases*"
  flag LIST --list -- "create list of packages contained in repos"

  flag BUILDLOG -l --log -- "[package-list] - show log of most recent build attempt"
  flag METRIC -m --metric -- "[package-list] - show 30-day download count for package"

  flag _SSH -s --ssh -- "ssh to chaotic server"
  flag RSYNC -r --rsync -- "download file from chaotic server"

  option USER -u --user on: "$_user" -- "set remote user"

  disp :usage -h --help
  disp VERSION --version
}

eval "$(getoptions parser_definition) exit 1"

## process input files
if [ $# -ge 1 ]; then
  if [ -f "$1" ]; then
    _input=$(bsdcat "$1" | sort -u)
  fi
fi

_user="${USER:-$_user}"

chaotic_prepare_packages() {
  local _file="packages.gz"
  local _data="${_working_dir:?}/$_file"
  [ ! -e "$_data" ] && aria2c "https://aur.archlinux.org/$_file" --dir="$_working_dir" -o "$_file"

  _packages_arch=$(
    expac -S '%r/%n %v' \
      | grep -E '^(core|extra|multilib)/' \
      | sed -E \
        -e 's@^\S+/@@' \
        -e 's@-([0-9]+\S*)$@-\1 0@; s@-([0-9]+)(\.([0-9]+)) 0$@-\1 \3@'
  )

  _packages_chaotic=$(pacman -Sql chaotic-aur)

  _packages_aur=$(bsdcat "${_data:?}")

  if [ -z "$_input" ]; then
    _input="$_packages_chaotic"
  fi
}

chaotic_prepare_pkgbase() {
  local _file="pkgbase.gz"
  local _data="${_working_dir:?}/$_file"
  [ ! -e "$_data" ] && aria2c "https://aur.archlinux.org/$_file" --dir="$_working_dir" -o "$_file"

  _packages_arch=$(
    expac -S '%r/%n %v' \
      | grep -E '^(core|extra|multilib)/' \
      | sed -E \
        -e 's@^\S+/@@' \
        -e 's@-([0-9]+\S*)$@-\1 0@; s@-([0-9]+)(\.([0-9]+)) 0$@-\1 \3@'
  )

  _packages_chaotic=$(pacman -Sql chaotic-aur)

  _packages_aur=$(bsdcat "${_data:?}")

  if [ -z "$_input" ]; then
    _input="$_packages_chaotic"
  fi
}

chaotic_prepare_meta() {
  # https://lists.archlinux.org/pipermail/aur-general/2021-November/036659.html
  local _file="packages-meta-ext-v1.json.gz"
  local _data="${_working_dir:?}/$_file"
  [ ! -e "$_data" ] && aria2c "https://aur.archlinux.org/$_file" --dir="$_working_dir" -o "$_file"
  [ ! -e "${_data%.gz}" ] && gzip -dk "$_data"
}

chaotic_check() (
  cd "${_output_dir:?}"

  # pkg-missing-aur = package in input, but not in aur
  comm -13 \
    <(sed -E 's@[ #:].*$@@' <<< "$_packages_aur" | sort -u) \
    <(sed -E "${_filter_list[@]}" <<< "$_input" | sort -u) \
    > pkg-missing-aur

  # pkg-missing-chaotic = package in input, but not in chaotic repo
  comm -13 \
    <(sed -E 's@[ #:].*$@@' <<< "$_packages_chaotic" | sort -u) \
    <(sed -E "${_filter_list[@]}" <<< "$_input" | sort -u) \
    > pkg-missing-chaotic

  # packages in input that are in arch
  comm -12 \
    <(sed -E 's@[ #:].*$@@' <<< "$_packages_arch" | sort -u) \
    <(sed -E 's@[ #:].*$@@' <<< "$_input" | sort -u) \
    > pkg-arch

  # packages in input that are in chaotic
  comm -12 \
    <(sed -E 's@[ #:].*$@@' <<< "$_packages_chaotic" | sort -u) \
    <(sed -E 's@[ #:].*$@@' <<< "$_input" | sort -u) \
    > pkg-chaotic
)

chaotic_list() (
  cd "${_output_dir:?}"

  cat <<< "$_packages_arch" > "packages-arch.txt"
  cat <<< "$_packages_chaotic" > "packages-chaotic.txt"

  cat <<< "$_packages_aur" > "packages-aur.txt"
)

chaotic_proc_path_pkg() {
  local _path _pkg
  _path="${1%[/,]}"

  if [ "$_path" = "." ]; then
    _pkg="${PWD##*/}"
  elif [ "${_path::1}" != "." ]; then
    _pkg="$_path"
  else
    >&2 echo "# error: package name cannot start with '.'"
    return 1
  fi

  if [ -e "$_path/.git" ] || grep -Eqm1 '^/home/[^/]$' <<< "$PWD"; then
    >&2 echo "# error: do not run on a git repo or home directory"
    return 1
  fi

  printf "%s::%s" "${_path:?}" "${_pkg:?}"
}

chaotic_log() {
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p _pkg _response
  for p in "$@"; do
    _pkg="${p%[/,]}"
    _response=$(curl -s --connect-timeout 3 -m 15 "https://builds.garudalinux.org/logs/api/logs/$_pkg")
    less -R <<< "$_response"
  done
}

chaotic_metric() {
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p n _pkg
  for p in "$@"; do
    _pkg="${p%[/,]}"
    n=$(curl -s "https://metrics.chaotic.cx/30d/package/$_pkg")
    printf '%s # %s\n' "$_pkg" "$n"
  done
}

chaotic_check_sync_aux() {
  local _path _pkg _old _new
  _path="${1:?}"
  _pkg="${2:?}"

  _old=$(git log -1 --pretty="format:%ct" -- "$_path")
  _new=$(grep -m1 '"PackageBase":"'${_pkg%/}'"' "$_working_dir/packages-meta-ext-v1.json" | grep -Eo '"LastModified":[0-9]+' | cut -d':' -f2)
  if [ "$_old" -lt "$_new" ]; then
    echo "$_pkg"
  else
    # echo "# $_pkg"
    :
  fi || echo "# error: $_pkg"
}

chaotic_check_sync() (
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  export -f chaotic_check_sync_aux
  export _working_dir

  local p _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    [ ! -f "$_path/.CI/config" ] && continue

    if grep -q 'CI_PKGBUILD_SOURCE=aur' "$_path/.CI/config"; then
      printf 'chaotic_check_sync_aux "%s" "%s"\n' "$_path" "$_pkg"
    fi
  done | parallel -j $((2 * $(nproc)))
)

chaotic_add() (
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p i _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    if [ ! -e "$_path/.CI" ]; then
      >&2 echo "# info: creating new package, $_pkg"
      install -Dm644 /dev/stdin "$_path/.CI/config" << END
CI_PKGBUILD_SOURCE=aur
END
      install -Dm644 /dev/stdin "$_path/.CI/info" << END
REQ_ORIGIN=github/${ISSUE:-}
REQ_REASON=request
END
    fi

    if [ -n "$EDIT" ]; then
      chaotic_edit "$_path"
    elif grep -Eqm1 '=github/$' "$_path/.CI/info"; then
      echo "# warning: $_path/.CI/info is incomplete"
    fi

    if ! grep -q 'CI_PKGBUILD_SOURCE=custom' "$_path/.CI/config"; then
      local _tmpname="tmp-$RANDOM"

      >&2 echo "# info: clearing destination directory"
      for i in "$_path"/* "$_path"/.*; do
        if [ -e "$i" ] && [ "$i" != "$_path/.CI" ]; then
          trash -f "$i"
        fi
      done

      if grep -q 'CI_PKGBUILD_SOURCE=https' "$_path/.CI/config"; then
        >&2 echo "# info: cloning git repo"
        _repo=$(grep -Eo -m1 'https://\S+' "$_path/.CI/config")
        git clone --depth=1 "$_repo" "$_path/$_tmpname"
      else
        >&2 echo "# info: downloading aur snapshot"
        aria2c "https://aur.archlinux.org/cgit/aur.git/snapshot/${_pkg:?}.tar.gz" -o "$_path/$_tmpname.tar.gz"
        mkdir -p "$_path/$_tmpname" && bsdtar -C "$_path/$_tmpname" --strip-components=1 -xf "$_path/$_tmpname.tar.gz"
      fi

      >&2 echo "# info: moving package files"
      mv "$_path/$_tmpname"/* "$_path/$_tmpname"/.* "$_path/"
      trash -f "$_path"/.git* "$_path/$_tmpname" "$_path/$_tmpname.tar.gz"

      >&2 echo "# info: running shfmt"
      shfmt -w "$_path"/PKGBUILD
    fi
  done
)

chaotic_bump() {
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p _tmp _path _pkg _current _pkgver _bump _msg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    _current=$(
      pacman -Si "chaotic-aur/$_pkg" 2> /dev/null \
        | grep -Pom1 '^Version\s+:\s+\K\S+$' \
        | sed -E 's&-([0-9]+)\.([0-9]+)$&-\1/\2&'
    )

    _pkgver=${_current%/*}
    _bump=${_current#*/}

    if [ "$_pkgver" = "$_bump" ]; then
      _bump=1
    else
      _bump=$((_bump + 1))
    fi

    echo "# bump: $_pkg $_pkgver/$_bump"
    if grep -qs '^CI_PACKAGE_BUMP=' "$_path/.CI/config"; then
      sed -E -e 's&(CI_PACKAGE_BUMP)=.*$&\1='"$_pkgver/$_bump&" -i "$_path/.CI/config"
    elif grep -qs '^CI_REBUILD_TRIGGERS=' "$_path/.CI/config"; then
      sed -E -e 's&(CI_REBUILD_TRIGGERS=.*)$&CI_PACKAGE_BUMP='"$_pkgver/$_bump"'\n\1&' -i "$_path/.CI/config"
    else
      sed -E -e 's&(CI_PKGBUILD_SOURCE=.*)$&CI_PACKAGE_BUMP='"$_pkgver/$_bump"'\n\1&' -i "$_path/.CI/config"
    fi
  done
}

# $1 = trigger
# $@ = packages
chaotic_trigger_rebuild() {
  if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    >&2 echo "# error: missing trigger/package names"
    return 1
  fi

  local _trigger p _tmp _path _pkg _pkgver _bump _msg
  _trigger="$1"
  shift

  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    if grep -qs '^CI_REBUILD_TRIGGERS=' "$_path/.CI/config"; then
      if ! grep -qs '^CI_REBUILD_TRIGGERS=.*'"$_trigger" "$_path/.CI/config"; then
        sed -E -e 's&(CI_REBUILD_TRIGGERS=\S+)$&\1:'"$_trigger" -i "$_path/.CI/config"
      fi
    else
      sed -E -e 's&(CI_PKGBUILD_SOURCE=.*)$&CI_REBUILD_TRIGGERS='"$_trigger"'\n\1&' -i "$_path/.CI/config"
    fi
  done
}

# $1 = trigger
# $@ = packages
chaotic_trigger_pipeline() {
  if [ $# -lt 2 ] || [ -z "$1" ] || [ -z "$2" ]; then
    >&2 echo "# error: missing trigger/package names"
    return 1
  fi

  local _trigger p _tmp _path _pkg _pkgver _bump _msg
  _trigger="$1"
  shift

  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    sed -e '1i CI_ON_TRIGGER='"$_trigger" -i "$_path/.CI/config"
  done
}

chaotic_edit() {
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    [ -e "$_path/.CI/config" ] && nano "$_path/.CI/config"
    [ -e "$_path/.CI/info" ] && nano "$_path/.CI/info"
  done
}

chaotic_commit() (
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    if [ -n "$EDIT" ]; then
      chaotic_edit "$_path"
    elif grep -Eqm1 '=github/$' "$_path/.CI/info"; then
      echo "# warning: $_path/.CI/info is incomplete"
    fi

    git add -f "$_path"
    git commit -m "feat($_pkg)${MSG:+: $MSG}" --no-edit
  done
)

chaotic_drop() (
  if [ $# -eq 0 ] || [ -z "$1" ]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    git rm -r "$_path"
    git commit -m "feat($_pkg): drop${MSG:+, $MSG}" --no-edit
  done
)

if [ "$CHECK" = 1 ]; then
  chaotic_prepare_packages
  chaotic_check
elif [ "$CHECKBASE" = 1 ]; then
  chaotic_prepare_pkgbase
  chaotic_check
elif [ "$CHECKSYNC" = 1 ]; then
  chaotic_prepare_meta
  chaotic_check_sync "$@"
elif [ "$LIST" = 1 ]; then
  chaotic_prepare_packages
  chaotic_list
elif [ "$_SSH" = 1 ]; then
  if [ -n "$1" ]; then
    _port="$1"
  else
    _port=400
  fi

  _cmd=(ssh -p "$_port" $_user@builds.garudalinux.org)
  echo "${_cmd[*]}"
  "${_cmd[@]}"
elif [ "$RSYNC" = 1 ]; then
  if [ -z "$1" ]; then
    >&2 echo "Error: Missing filename"
    exit 1
  elif [ "${1::2}" = "./" ]; then
    _cmd=(scp -P 400 $_user@builds.garudalinux.org:"/home/$_user/$_build_dir_remote/${1:2}" .)
  elif [ "${1::6}" = "/repo/" ]; then
    _cmd=(scp -P 400 $_user@builds.garudalinux.org:"/home/$_user/$_build_dir_remote/${1:1}" .)
  elif [ "${1::1}" = "/" ]; then
    _cmd=(scp -P 400 $_user@builds.garudalinux.org:"$1" .)
  else
    _cmd=(scp -P 400 $_user@builds.garudalinux.org:"/home/$_user/$_build_dir_remote/repo/builder/x86_64/$1" .)
  fi

  echo "${_cmd[*]}"
  "${_cmd[@]}"
elif [ "$BUILDLOG" = 1 ]; then
  chaotic_log "$@"
elif [ "$ADD" = 1 ]; then
  chaotic_add "$@"
elif [ "$BUMP" = 1 ]; then
  chaotic_bump "$@"
elif [ "$DROP" = 1 ]; then
  chaotic_drop "$@"
elif [ "$EDIT" = 1 ]; then
  chaotic_edit "$@"
elif [ "$COMMIT" = 1 ]; then
  chaotic_commit "$@"
elif [ "$TRIGGER_REBUILD" = 1 ]; then
  chaotic_trigger_rebuild "$@"
elif [ "$TRIGGER_PIPELINE" = 1 ]; then
  chaotic_trigger_pipeline "$@"
elif [ "$METRIC" = 1 ]; then
  chaotic_metric "$@"
else
  usage
  exit 1
fi
