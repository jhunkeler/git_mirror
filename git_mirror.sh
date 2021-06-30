#!/usr/bin/env bash

# Disable blocking for authentication and invalid repository URLs
export GIT_TERMINAL_PROMPT=0

# Record of errors encountered during execution
errors=0

# Fail if not enough arguments
if [[ $# < 1 ]]; then
    echo "usage: $(basename $0) {config}"
    exit 1
fi

# Obtain configuration file path
config="$1"
if [[ ! -f "$config" ]]; then
    echo "'$config' does not exist" >&2
    exit 1
fi

# Load configuration
source "$config"
repositories_len=${#repositories[@]}

# Check configuration sanity
if [[ -z "$dest" ]]; then
    echo "$config: 'dest' path undefined" >&2
    exit 1
fi

if (( ! repositories_len )); then
    echo "$config: 'repositories' array undefined or empty" >&2
    exit 1
fi

# Check destination sanity
if [[ ! -d "$dest" ]]; then
    mkdir -p "$dest" || exit 1
fi

if [[ ! -w "$dest" ]]; then
    echo "$dest: insufficient permission to write to destination directory" >&2
    exit 1
fi

# Begin
echo "---"
for repo in "${repositories[@]}"; do
    # Normalize repository output name to include '.git', because '--mirror' appends
    # it automatically to the destination directory
    name="$(basename $repo)"
    if [[ ! $name =~ .*\.git$ ]]; then
        name="${name}.git"
    fi

    # Update a mirrored repo, or clone it
    output="$dest/$name"
    if git --git-dir="$output" rev-parse &>/dev/null || [[ -d "${output}/.git" ]]; then
        echo "Updating: $output"
        pushd "$output" &>/dev/null
        git fetch --all || (( errors++ ))
        popd &>/dev/null
    else
        echo "Mirroring: $repo"
        git clone --mirror "$repo" "$output" || (( errors++ ))
    fi
    echo "---"
done

if (( errors )); then
    echo "done, with $errors error(s)!"
else
    echo "done!"
fi
