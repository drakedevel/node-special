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
suffix=""

# Handle sanitizers
enabled "$asan" && flags+=(--enable-asan)
enabled "$ubsan" && flags+=(--enable-ubsan)
if enabled "$asan" && enabled "$ubsan"; then
    suffix+="-uasan"
elif enabled "$asan"; then
    suffix+="-asan"
elif enabled "$ubsan"; then
    suffix+="-ubsan"
fi

# Handle debug
if enabled "$debug"; then
    flags+=(--debug --v8-with-dchecks)
    suffix+="-debug"
fi

# Handle no flags
if [[ -z "$suffix" ]]; then
    suffix+="-vanilla"
fi

echo "Configuration flags: ${flags[*]}"
echo "Image tag suffix: ${suffix}"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "configFlags=${flags[*]}" >> "$GITHUB_OUTPUT"
    echo "tagSuffix=${suffix}" >> "$GITHUB_OUTPUT"
fi
