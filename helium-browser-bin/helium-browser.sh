#!/bin/bash
# Maintainer: Sam Sinclair <sam at playleft dot com>
# Contributor: Pujan Modha <pujan.pm@hotmail.com>
# Contributor: init_harsh
# /*
#  * SPDX-FileCopyrightText: 2025 Arch Linux Contributors
#  *
#  * SPDX-License-Identifier: 0BSD
#  */
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-"$HOME/.config"}"

SYS_CONF="/etc/helium-browser-flags.conf"
USR_CONF="${XDG_CONFIG_HOME}/helium-browser-flags.conf"

FLAGS=()

append_flags_file() {
  local file="$1"
  [[ -r "$file" ]] || return 0
  local line safe_line
  # Filter comments & blank lines
  while IFS= read -r line; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    # Sanitise: block command substitution; prevent $VAR and ~ expansion
    case "$line" in
      *'$('*|*'`'*)
        echo "Warning: ignoring unsafe line in $file: $line" >&2
        continue
        ;;
    esac
    # Disable globbing during eval
    set -f
    # Prevent $VAR and ~ expansion while allowing eval to parse quotes & escapes
    safe_line=${line//$/\\$}
    safe_line=${safe_line//~/\\~}
    eval "set -- $safe_line"
    # Enable globbing for rest of the script
    set +f
    for token in "$@"; do
      FLAGS+=("$token")
    done
  done < "$file"
}

append_flags_file "$SYS_CONF"
append_flags_file "$USR_CONF"

# Add environment var $HELIUM_USER_FLAGS
if [[ -n "${HELIUM_USER_FLAGS:-}" ]]; then
  # Split env contents on whitespace; users can quote if needed.
  read -r -a ENV_FLAGS <<< "$HELIUM_USER_FLAGS"
  FLAGS+=("${ENV_FLAGS[@]}")
fi

# Let the wrapped binary know that it has been run through the wrapper.
export CHROME_WRAPPER="`readlink -f "$0"`"

# Set Chromium version to 'stable'
export CHROME_VERSION_EXTRA="stable"

# Sanitize std{in,out,err} because they'll be shared with untrusted child
# processes (http://crbug.com/376567).
exec < /dev/null
exec > >(exec cat)
exec 2> >(exec cat >&2)

# -a "$0" makes the process appear as the name of the wrapper, i.e.
# 'helium-browser'. This doesn't affect Kernel level process naming.
exec -a "$0" /opt/helium-browser-bin/chrome "${FLAGS[@]}" "$@"

