#!/bin/bash
set -o pipefail
_APPDIR="/usr/lib/@appname@"
_RUNNAME="${_APPDIR}/@runname@"
export PATH="${_APPDIR}/usr/bin:${_APPDIR}/usr/bin/JRE/bin:${_APPDIR}/usr/bin/Library:$PATH}"
export LD_LIBRARY_PATH="${_APPDIR}/usr/lib/x86_64-linux-gnu:${_APPDIR}/usr/bin/JRE/lib:${LD_LIBRARY_PATH}"
cd "${_APPDIR}" || { echo "Failed to change directory to ${_APPDIR}"; exit 1; }
exec "${_RUNNAME}" "$@" || exit $?