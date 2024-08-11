#!/bin/bash
set -eu

if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 <asan> <debug> <ubsan>" >&2
    exit 1
fi
asan="$1"
debug="$2"
ubsan="$3"

function enabled() {
    [[ "$1" == "true" ]]
}
flags=()
desc_flags=()
suffix=""

# Handle sanitizers
enabled "$asan" && flags+=(--enable-asan) && desc_flags+=(ASan)
enabled "$ubsan" && flags+=(--enable-ubsan) && desc_flags+=(UBSan)
if enabled "$asan" && enabled "$ubsan"; then
    suffix+='-uasan'
elif enabled "$asan"; then
    suffix+='-asan'
elif enabled "$ubsan"; then
    suffix+='-ubsan'
fi

# Handle debug
if enabled "$debug"; then
    flags+=(--debug --v8-with-dchecks)
    desc_flags+=('debug checks')
    suffix+='-debug'
fi

# Handle no flags
if [[ -z "$suffix" ]]; then
    suffix+='-vanilla'
fi

# Create human-readable description
if [[ "${#desc_flags[@]}" -eq 0 ]]; then
    desc='default features'
elif [[ "${#desc_flags[@]}" -eq 1 ]]; then
    desc="${desc_flags[0]}"
elif [[ "${#desc_flags[@]}" -eq 2 ]]; then
    desc="${desc_flags[0]} and ${desc_flags[1]}"
else
    desc="${desc_flags[0]}"
    for df in "${desc_flags[@]:1:${#desc_flags[@]}-2}"; do
        desc+=", ${df}"
    done
    desc+=", and ${desc_flags[-1]}"
fi

echo "Configuration flags: ${flags[*]}"
echo "Features: ${desc}"
echo "Image tag suffix: ${suffix}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    {
        echo "configFlags=${flags[*]}"
        echo "featureDesc=${desc}"
        echo "tagSuffix=${suffix}"
    } >> "$GITHUB_OUTPUT"
fi
