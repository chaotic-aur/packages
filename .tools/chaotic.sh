#!/usr/bin/env bash
# deps: aria2 devtools git getoptions shfmt trash-cli

VERSION="0.0.11"

_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/chaotic/chaotic.sh.conf"

parser_definition() {
  setup REST help:usage -- "Usage: $(basename $0) [options]... [INPUT]"
  msg -- ''
  msg -- 'Basic chaotic-aur management tasks.'
  msg -- ''
  msg -- 'Options:'
  flag ADD -a --add -- "[package-list] - add or update packages"
  flag SKIP_AUR --skip-aur -- "implies add, download from github mirror"
  flag SNAPSHOT --snapshot -- "implies add, download aur snapshot (tarball)"
  msg -- ''
  flag BUMP -b --bump -- "[package-list] - bump pkgrel of packages"
  flag DROP -d --drop -- "[package-list] - drop packages"
  flag CLONE --clone -- "[package-list] - clone AUR or Arch package repo"
  msg -- ''
  flag TRIGGER_REBUILD --trigger-rebuild --tr -- "[trigger-package] [package-list] - add rebuild trigger to packages"
  flag TRIGGER_PIPELINE --trigger-pipeline --tp -- "[trigger-name] [package-list] - add pipeline trigger to packages"
  msg -- ''
  flag COMMIT --commit -- "[package-list] - commit packages"
  param MSG --msg -- "commit message"
  flag EDIT -e --edit -- "edit config/info of packages"
  param ISSUE -n --issue -- "github issue number"
  msg -- ''
  flag CHECKSYNC --check-sync --cs -- "[package-list] - check package sync with aur"
  flag NVCHECKER --check-nvchecker --cn -- "[package-list] - check custom packages for updates with nvchecker"
  flag CHECKORPHAN --check-orphan --co -- "[package-list] - check whether packages are orphaned"
  flag CHECKOUTDATED --check-outdated --ood -- "[package-list] - check whether packages are outdated"
  flag CHECK_ALL --all -- "check all packages; applies to nvchecker, orphan, outdated"
  msg -- ''
  flag CHECK -c --check -- "create lists of broken/missing *packages*"
  flag CHECKBASE --check-base -- "create list of broken/missing *pkgbases*"
  flag LIST --list -- "create list of packages contained in repos"
  msg -- ''
  flag BUILDLOG -l --log -- "[package-list] - show log of most recent build attempt"
  flag METRIC -m --metric -- "[package-list] - show 30-day download count for package"
  msg -- ''
  flag SSH -s --ssh -- "ssh to chaotic server"
  flag RSYNC -r --rsync -- "download file from chaotic server"
  param USER -u --user -- "set remote user"
  msg -- ''
  disp :usage -h --help
  disp VERSION --version
}

chaotic_load_config() {
  if [[ ! -f "$_config_file" ]]; then
    install -Dm644 /dev/stdin "$_config_file" << END
_script_dir=\$(dirname \$(readlink -f \$0))

_output_dir="/tmp"
_working_dir="/tmp"

_build_dir_remote="build"

_user="\$(whoami)"
_port=210

_jobs=-1
_refresh_age=3600

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
}

chaotic_process_input() {
  if [[ $# -gt 0 ]]; then
    if [[ -f "$1" ]]; then
      _input=$(bsdcat "$1" | sort -u)
    fi
  fi
}

# https://lists.archlinux.org/pipermail/aur-general/2021-November/036659.html
chaotic_download_aur_data() {
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
    >&2 echo "# error: missing file name"
    return 1
  fi

  local _file="$1"
  _data_file="${_working_dir:?}/$_file"

  local _max_age="${_refresh_age:-3600}"
  local _now=$(date +%s)
  local _mtime=$(stat -c %Y "$_data_file" 2> /dev/null || echo 0)

  if ((_now - _mtime > _max_age)); then
    trash -f "$_data_file" "${_data_file%.gz}"
    aria2c "https://aur.archlinux.org/$_file" --dir="$_working_dir" -o "$_file"
  fi

  if [[ "$_data_file" =~ json ]] && [[ ! -e "${_data_file%.gz}" ]]; then
    gzip -dk "$_data_file"
  fi
}

chaotic_prepare_meta() {
  chaotic_download_aur_data "packages-meta-ext-v1.json.gz" || return 1
}

chaotic_prepare_packages() {
  chaotic_download_aur_data "packages.gz" || return 1

  _packages_arch=$(
    expac -S '%r/%n %v' \
      | grep -E '^(core|extra|multilib)/' \
      | sed -E \
        -e 's@^\S+/@@' \
        -e 's@-([0-9]+\S*)$@-\1 0@; s@-([0-9]+)(\.([0-9]+)) 0$@-\1 \3@'
  )

  _packages_chaotic=$(pacman -Sql chaotic-aur)

  _packages_aur=$(bsdcat "${_data_file:?}")

  if [[ -z "$_input" ]]; then
    _input="$_packages_chaotic"
  fi
}

chaotic_prepare_pkgbase() {
  chaotic_download_aur_data "pkgbase.gz" || return 1

  _packages_arch=$(
    expac -S '%r/%n %v' \
      | grep -E '^(core|extra|multilib)/' \
      | sed -E \
        -e 's@^\S+/@@' \
        -e 's@-([0-9]+\S*)$@-\1 0@; s@-([0-9]+)(\.([0-9]+)) 0$@-\1 \3@'
  )

  _packages_chaotic=$(pacman -Sql chaotic-aur)

  _packages_aur=$(bsdcat "${_data_file:?}")

  if [[ -z "$_input" ]]; then
    _input="$_packages_chaotic"
  fi
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

  printf '%s\n' "$_packages_arch" > "packages-arch.txt"
  printf '%s\n' "$_packages_chaotic" > "packages-chaotic.txt"

  printf '%s\n' "$_packages_aur" > "packages-aur.txt"
)

chaotic_proc_path_pkg() {
  local _path _pkg
  _path="${1%[/,]}"

  if [[ "$_path" = "." ]]; then
    _pkg="${PWD##*/}"
  elif [[ "${_path::1}" != "." ]]; then
    _pkg="$_path"
  else
    >&2 echo "# error: package name cannot start with '.'"
    return 1
  fi

  if [[ -e "$_path/.git" ]]; then
    >&2 echo "# error: package directory cannot be a git repo"
    return 1
  fi

  printf "%s::%s" "${_path:?}" "${_pkg:?}"
}

chaotic_log() {
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local p r n _pkg
  for p in "$@"; do
    _pkg="${p%[/,]}"
    r=$(curl -s "https://backend.chaotic.cx/metrics/package/${_pkg}?days=30")
    n=$(grep -Pom1 '"downloads":\K[0-9]+' <<< "$r")
    printf '%s # %s\n' "$_pkg" "$n"
  done
}

chaotic_check_sync_aux() {
  local _path _pkg _old _old_at _old_ct _new
  _path="${1:?}"
  _pkg="${2:?}"

  _old_at=$(git log -1 --pretty="format:%at" -- "$_path") # author date
  _old_ct=$(git log -1 --pretty="format:%ct" -- "$_path") # commit date

  _old=$((_old_at > _old_ct ? _old_at : _old_ct))
  _new=$(
    grep -m1 "$(printf '"PackageBase":"%s"' "${_pkg%/}")" "$_working_dir/packages-meta-ext-v1.json" \
      | grep -Eo '"LastModified":[0-9]+' \
      | cut -d':' -f2
  )

  if [[ $_old =~ ^[0-9]{10,}$ ]] && [[ $_new =~ ^[0-9]{10,}$ ]]; then
    ((_old < _new)) && echo "$_pkg"
  else
    echo "# error: $_pkg"
    echo
  fi
}

chaotic_check_orphan_aux() {
  local _path _pkg
  _path="${1:?}"
  _pkg="${2:?}"

  if grep -qm1 "$(printf '"PackageBase":"%s".*"Maintainer":null' "${_pkg%/}")" "$_working_dir/packages-meta-ext-v1.json"; then
    echo "${_pkg%/}"
  fi
}

chaotic_check_outdated_aux() {
  local _path _pkg _pkgdate
  _path="${1:?}"
  _pkg="${2:?}"

  _pkgdate=$(grep -Pom1 "$(printf '"PackageBase":"%s".*"OutOfDate":\K[0-9]+' "${_pkg%/}")" "$_working_dir/packages-meta-ext-v1.json")
  if [[ -n "$_pkgdate" ]]; then
    printf '%-40s # %s\n' "${_pkg%/}" "$(\date -d "@${_pkgdate}" '+%Y-%m-%d %H:%M:%S')"
  fi
}

chaotic_check_packages() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
    >&2 echo "# error: missing function name"
    return 1
  fi

  if [[ $# -eq 0 ]] || [[ -z "$2" ]]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local _aux_function="$1"
  export -f "$_aux_function"
  export _working_dir

  local p _tmp _path _pkg
  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    if ((!CHECK_ALL)); then
      if [[ ! -f "$_path/.CI/config" ]]; then
        continue
      fi

      if ! grep -q 'CI_PKGBUILD_SOURCE=aur' "$_path/.CI/config"; then
        continue
      fi
    fi

    printf '%s "%s" "%s"\n' "$_aux_function" "$_path" "$_pkg"
  done | parallel -j "${_jobs:--1}"
)

chaotic_check_nvchecker() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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

    if ((!CHECK_ALL)); then
      if [[ ! -f "$_path/.CI/config" ]]; then
        continue
      fi

      if ! grep -q 'CI_PKGBUILD_SOURCE=custom' "$_path/.CI/config"; then
        continue
      fi

      if ! grep -q 'CI_NVCHECKER=true' "$_path/.CI/config"; then
        continue
      fi
    fi

    if [ -e "$_path/.nvchecker.toml" ]; then
      pkgctl version check "$_path"
    fi
  done
)

chaotic_add() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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

    if [[ ! -e "$_path/.CI" ]]; then
      >&2 echo "# info: creating new package, $_pkg"
      install -Dm644 /dev/stdin "$_path/.CI/config" << END
CI_PKGBUILD_SOURCE=aur
END
      install -Dm644 /dev/stdin "$_path/.CI/info" << END
REQ_ORIGIN=github/${ISSUE:-}
REQ_REASON=request
END
    fi

    if ! grep -q 'CI_PKGBUILD_SOURCE=custom' "$_path/.CI/config"; then
      local _repo _git_opts
      local _tmpname="tmp-$RANDOM"

      if grep -q 'CI_PKGBUILD_SOURCE=https' "$_path/.CI/config"; then
        >&2 echo "# info: cloning git repo"
        _repo=$(grep -Eo -m1 'https://\S+' "$_path/.CI/config")
        _git_opts=(clone --depth=1)
        git "${_git_opts[@]}" "$_repo" "$_path/$_tmpname"
      else
        local _pkg_url_bases=(
          "https://aur.archlinux.org/cgit/aur.git/snapshot"
          "https://github.com/archlinux/aur/archive/refs/heads"
        )

        for _pkg_url_base in "${_pkg_url_bases[@]}"; do
          if [[ "${SKIP_AUR:-0}" -ne 0 && "${_pkg_url_base}" =~ aur\.archlinux\.org ]]; then
            continue
          else
            if ((!SNAPSHOT)); then
              if [[ "${_pkg_url_base}" =~ aur\.archlinux\.org ]]; then
                >&2 echo "# info: cloning aur repo"
                _repo="https://aur.archlinux.org/${_pkg:?}.git"
                _git_opts=(clone --depth=1)
              elif [[ "${_pkg_url_base}" =~ github.com ]]; then
                >&2 echo "# info: cloning github mirror"
                _repo="https://github.com/archlinux/aur.git"
                _git_opts=(clone --depth=1 --branch="${_pkg:?}")
              fi

              if git "${_git_opts[@]}" "$_repo" "$_path/$_tmpname"; then
                break
              fi
            elif [[ "${SKIP_AUR:-0}" -eq 0 && "${_pkg_url_base}" =~ aur\.archlinux\.org ]]; then
              >&2 echo "# warning: AUR snapshot failed, falling back to GitHub"
              SKIP_AUR=1
            else
              >&2 echo "# info: downloading aur snapshot"
              if aria2c --timeout=10 --max-tries=1 "${_pkg_url_base}/${_pkg:?}.tar.gz" -o "$_path/$_tmpname.tar.gz"; then
                mkdir -p "$_path/$_tmpname" && bsdtar -C "$_path/$_tmpname" --strip-components=1 -xf "$_path/$_tmpname.tar.gz"
                break
              fi
            fi
          fi
        done
      fi

      if [[ -f "$_path/$_tmpname/.git/config" || -f "$_path/$_tmpname/PKGBUILD" ]]; then
        >&2 echo "# info: clearing destination directory"
        for i in "$_path"/* "$_path"/.*; do
          if [[ -e "$i" && "$i" != "$_path/.CI" && "$i" != "$_path/$_tmpname" ]]; then
            trash -f ./"$i"
          fi
        done

        >&2 echo "# info: moving package files"
        local _rsync_options=(
          -a --delete-after
          --chmod=F644
          --exclude "$_tmpname"
          --exclude '.CI'
          --exclude '.git*'
          --exclude 'LICENSES'
          --exclude 'keys'
        )
        rsync "${_rsync_options[@]}" "$_path/$_tmpname/" "$_path/" || >&2 echo "# error: failed to copy files"
      else
        >&2 echo "# error: download failed"
      fi

      >&2 echo "# info: removing temporary files"
      trash -f ./"$_path/$_tmpname"*

      >&2 echo "# info: running shfmt"
      shfmt -w "$_path"/PKGBUILD
    fi
  done
)

chaotic_bump() {
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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

    if [[ ! -f "$_path/.CI/config" ]]; then
      echo "# warn: package does not exist, $_pkg"
      continue
    fi

    _current=$(
      pacman -Si "chaotic-aur/$_pkg" 2> /dev/null \
        | grep -Pom1 '^Version\s+:\s+\K\S+$' \
        | sed -E 's&-([0-9]+)\.([0-9]+)$&-\1/\2&'
    )

    if [[ -z "$_current" ]]; then
      echo "# warn: unable to obtain package version, $_pkg"
      continue
    fi

    _pkgver=${_current%/*}
    _bump=${_current#*/}

    if [[ "$_pkgver" = "$_bump" ]]; then
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

chaotic_clone() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
    >&2 echo "# error: missing package name"
    return 1
  fi

  local _pkg _repo_clone_url
  for _pkg in "$@"; do
    # check if aurweb page exists; don't clone deleted packages
    if ! curl -Issf "https://aur.archlinux.org/pkgbase/$_pkg" &> /dev/null; then
      # clone if arch repo exists
      _repo_clone_url="https://gitlab.archlinux.org/archlinux/packaging/packages"
      if git -c credential.interactive=never ls-remote "$_repo_clone_url/$_pkg.git" 2> /dev/null; then
        >&2 echo "# info: cloning package from Arch repo, $_pkg"
        git clone "$_repo_clone_url/$_pkg.git" "$_pkg.arch"
        break
      fi

      # else warn doesn't exist ... clone later
      >&2 echo "# warn: package does not exist, $_pkg"
    fi

    # clone from AUR whether exists or not
    >&2 echo "# info: cloning package from AUR repo, $_pkg"
    _repo_clone_url="https://aur.archlinux.org"
    git clone "$_repo_clone_url/$_pkg.git" "$_pkg.aur"
  done
)

# $1 = trigger
# $@ = packages
chaotic_trigger_rebuild() {
  if [[ $# -lt 2 ]] || [[ -z "$1" ]] || [[ -z "$2" ]]; then
    >&2 echo "# error: missing trigger/package names"
    return 1
  fi

  local _trigger p _tmp _path _pkg _pkgver _bump _msg _trigger_list
  _trigger="$1"
  shift

  for p in "$@"; do
    if _tmp="$(chaotic_proc_path_pkg "$p")"; then
      _path="${_tmp%%::*}"
      _pkg="${_tmp##*::}"
    else
      continue
    fi

    if [[ ! -f "$_path/.CI/config" ]]; then
      echo "# warn: package does not exist, $_pkg"
      continue
    fi

    if grep -qs '^CI_REBUILD_TRIGGERS=' "$_path/.CI/config"; then
      _trigger_list=$(
        sort -u \
          <(grep -Po 'CI_REBUILD_TRIGGERS=\K\S+' "$_path/.CI/config" | tr ':' '\n') \
          <(printf '%s\n' "$_trigger") \
          | paste -sd ':'
      )
      if ! grep -qs '^CI_REBUILD_TRIGGERS=.*'"$_trigger" "$_path/.CI/config"; then
        sed -E -e 's&(CI_REBUILD_TRIGGERS)=\S+$&\1='"${_trigger_list}&" -i "$_path/.CI/config"
        >&2 echo "# info: updating $_pkg triggers: $_trigger_list"
      else
        >&2 echo "# info: no change to $_pkg triggers: $_trigger_list"
      fi
    else
      sed -E -e 's&(CI_PKGBUILD_SOURCE=.*)$&CI_REBUILD_TRIGGERS='"$_trigger"'\n\1&' -i "$_path/.CI/config"
      >&2 echo "# info: adding $_pkg trigger: $_trigger"
    fi
  done
}

# $1 = trigger
# $@ = packages
chaotic_trigger_pipeline() {
  if [[ $# -lt 2 ]] || [[ -z "$1" ]] || [[ -z "$2" ]]; then
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

    if [[ ! -f "$_path/.CI/config" ]]; then
      echo "# warn: package does not exist, $_pkg"
      continue
    fi

    sed -e '1i CI_ON_TRIGGER='"$_trigger" -i "$_path/.CI/config"
  done
}

chaotic_edit() {
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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

    [[ -e "$_path/.CI/config" ]] && nano "$_path/.CI/config"
    [[ -e "$_path/.CI/info" ]] && nano "$_path/.CI/info"
  done
}

chaotic_commit() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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

    git add -f "$_path"
    if ((ADD)); then
      git commit -m "feat($_pkg): ${MSG:+, $MSG}" --no-edit
    fi
  done

  local _pkg_list _collect
  mapfile -t _collect < <(git diff --cached --name-only | cut -d'/' -f1 | sort -u)

  if [[ "${#_collect[@]}" -gt 0 ]]; then
    if ((DROP)); then
      if [[ "${#_collect[@]}" = 1 ]]; then
        git commit -m "feat(${_collect[*]}): drop${MSG:+, $MSG}" --no-edit
      else
        _pkg_list="${_collect[*]}"
        git commit -m "chore(drop): ${_pkg_list// /, }" --no-edit
      fi
    elif ((BUMP)); then
      _pkg_list="${_collect[*]}"
      git commit -m "chore(bump): ${_pkg_list// /, }" --no-edit
    elif [[ "$MSG" =~ ^update$ ]]; then
      _pkg_list="${_collect[*]}"
      git commit -m "chore(update): ${_pkg_list// /, }" --no-edit
    else
      if [[ "${#_collect[@]}" = 1 ]]; then
        git commit -m "feat(${_collect[*]})${MSG:+: $MSG}" --no-edit
      else
        _pkg_list="${_collect[*]}"
        git commit -m "chore(init): ${_pkg_list// /, }" --no-edit
      fi
    fi
    echo "# info: ${#_collect[@]} packages changed"
  fi
)

chaotic_drop() (
  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
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
  done
)

chaotic_ssh() {
  if [[ -n "$1" ]]; then
    _port="$1"
  fi

  _cmd=(ssh -p "$_port" ${USER}@builds.garudalinux.org)
  echo "${_cmd[*]}"
  "${_cmd[@]}"
}

chaotic_rsync() {
  if [[ -z "$1" ]]; then
    >&2 echo "Error: Missing filename"
    exit 1
  elif [[ "${1::2}" = "./" ]]; then
    _cmd=(scp -P $_port ${USER}@builds.garudalinux.org:"/home/${USER}/$_build_dir_remote/${1:2}" .)
  elif [[ "${1::6}" = "/repo/" ]]; then
    _cmd=(scp -P $_port ${USER}@builds.garudalinux.org:"/home/${USER}/$_build_dir_remote/${1:1}" .)
  elif [[ "${1::1}" = "/" ]]; then
    _cmd=(scp -P $_port ${USER}@builds.garudalinux.org:"$1" .)
  else
    _cmd=(scp -P $_port ${USER}@builds.garudalinux.org:"/home/${USER}/$_build_dir_remote/repo/builder/x86_64/$1" .)
  fi

  echo "${_cmd[*]}"
  "${_cmd[@]}"
}

chaotic_safety_nonroot() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Do not run as root user."
    return 1
  fi
}

_unsafe_dispatch() {
  if ! grep -qPm1 '^\s*url\s*=\s*\S+[:/]chaotic-aur/(packages|pkgbuilds)\.git' .git/config ../.git/config 2> /dev/null; then
    echo "error: must be within the chaotic-aur/packages repo"
    return 1
  fi

  if grep -Eqm1 '^/home(/[^/]+)?$' <<< "$PWD"; then
    >&2 echo "# error: do not in home directory"
    return 1
  fi

  if [[ $# -eq 0 ]] || [[ -z "$1" ]]; then
    >&2 echo "# error: missing function name, $0"
    return 1
  fi

  eval "$(printf '%q ' "$@")"
}

## preflight
chaotic_safety_nonroot || exit 1

if (($# == 0)); then
  set -- --help
fi

chaotic_load_config

## parse options
eval "$(getoptions parser_definition) exit 1"

if ((SKIP_AUR || SNAPSHOT)); then
  ADD=1
fi

: ${USER:=${_user:-$(whoami)}}

## dispatch
if ((CHECK)); then
  chaotic_process_input "$1"
  chaotic_prepare_packages
  chaotic_check
fi

if ((CHECKBASE)); then
  chaotic_process_input "$1"
  chaotic_prepare_pkgbase
  chaotic_check
fi

if ((LIST)); then
  chaotic_prepare_packages
  chaotic_list
fi

((CLONE)) && chaotic_clone "$@"
((BUILDLOG)) && chaotic_log "$@"
((METRIC)) && chaotic_metric "$@"
((SSH)) && chaotic_ssh "$@"
((RSYNC)) && chaotic_rsync "$@"

## unsafe dispatch, must run within repo
if ((CHECKSYNC)); then
  chaotic_prepare_meta
  _unsafe_dispatch chaotic_check_packages chaotic_check_sync_aux "$@" || exit 1
fi

if ((CHECKORPHAN)); then
  chaotic_prepare_meta
  _unsafe_dispatch chaotic_check_packages chaotic_check_orphan_aux "$@" || exit 1
fi

if ((CHECKOUTDATED)); then
  chaotic_prepare_meta
  _unsafe_dispatch chaotic_check_packages chaotic_check_outdated_aux "$@" || exit 1
fi

((NVCHECKER)) && (_unsafe_dispatch chaotic_check_nvchecker "$@" || exit 1)

((ADD)) && (_unsafe_dispatch chaotic_add "$@" || exit 1)
((BUMP)) && (_unsafe_dispatch chaotic_bump "$@" || exit 1) && COMMIT=1
((DROP)) && (_unsafe_dispatch chaotic_drop "$@" || exit 1) && COMMIT=1

((TRIGGER_REBUILD)) && (_unsafe_dispatch chaotic_trigger_rebuild "$@" || exit 1)
((TRIGGER_PIPELINE)) && (_unsafe_dispatch chaotic_trigger_pipeline "$@" || exit 1)

((EDIT)) && (_unsafe_dispatch chaotic_edit "$@" || exit 1)
((COMMIT)) && (_unsafe_dispatch chaotic_commit "$@" || exit 1)
