#/usr/bin/env bash

readonly _LINUX_LTS='54'
readonly _LINUX_STABLE='57'

readonly _LINUX_SCHED=(
    'pds 0'
    'bmq 1'
    'muqss 0'
)

readonly _LINUX_MARCH=('generic'
    'atom' 'barcelona' 'bobcat' 'broadwell'
    'bulldozer' 'cannonlake' 'core2'
    'haswell' 'icelake' 'ivybridge' 'jaguar'
    'k10' 'k8' 'k8sse3' 'mpsc' 'nehalem'
    'sandybridge' 'silvermont'
    'skylake' 'skylakex'
    'westmere' 'zen' 'zen2'
)

for _VAR_SCHED in "${_LINUX_SCHED[@]}"; do
    echo $_VAR_SCHED 'generic' 'lts'
done

for _VAR_SCHED in "${_LINUX_SCHED[@]}"; do
    for _VAR_MARCH in "${_LINUX_MARCH[@]}"; do
        echo $_VAR_SCHED $_VAR_MARCH
    done
done