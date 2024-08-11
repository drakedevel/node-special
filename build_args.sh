#!/bin/bash
set -eu

if [[ "$#" -ne 2 ]]; then
    echo "Usage: $0 <asan> <debug>" >&2
    exit 1
fi
asan="$1"
debug="$2"

function enabled() {
    [[ "$1" == "true" ]]
}
flags=()
suffix=""

# Handle sanitizers
if enabled "$asan"; then
    suffix="${suffix}-asan"
    flags+=(--enable-asan)
fi

# Handle debug
if enabled "$debug"; then
    suffix="${suffix}-debug"
    flags+=(--debug --v8-with-dchecks)
fi

# Handle no flags
if [[ -z "$suffix" ]]; then
    suffix="-vanilla"
fi

echo "Configuration flags: ${flags[@]}"
echo "Image tag suffix: ${suffix}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "configFlags=${flags[@]}" >> "$GITHUB_OUTPUT"
    echo "tagSuffix=${suffix}" >> "$GITHUB_OUTPUT"
fi
