#!/bin/sh
set -e

write_output () {
    local output="$1"
    if [ -n "$output_to_file" ]; then
        local file_output="$2"
        if [ -z "$file_output" ]; then
            file_output=$output
        fi
        echo "$file_output" >> "$output_to_file"
    fi
    # github-action limits output to 1MB
    # we count bytes because unicode has multibyte characters
    size=$(echo "$output" | wc -c)
    if [ "$size" -ge "1000000" ]; then
        echo "WARN: diff exceeds the 1MB limit, truncating output..." >&2
        output=$(echo "$output" | head -c 1000000)
    fi
    echo "$output" >>"$GITHUB_OUTPUT"
}

readonly base="$1"
readonly revision="$2"
readonly params="$3"
readonly output_to_file="$4"

echo "running oasdiff changelog base: $base, revision: $revision, parameters: $params, output_to_file: $output_to_file"

set -o pipefail

# *** github action step output ***

# output name should be in the syntax of multiple lines:
# {name}<<{delimiter}
# {value}
# {delimiter}
# see: https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings
delimiter=$(cat /proc/sys/kernel/random/uuid | tr -d '-')
echo "changelog<<$delimiter" >>"$GITHUB_OUTPUT"

if [ -n "$params" ]; then
    output=$(oasdiff changelog "$base" "$revision" "$params")
else
    output=$(oasdiff changelog "$base" "$revision")
fi

if [ -n "$output" ]; then
    write_output "$output"
else
    write_output "No changelog changes"
fi

echo "$delimiter" >>"$GITHUB_OUTPUT"

# *** github action step output ***

