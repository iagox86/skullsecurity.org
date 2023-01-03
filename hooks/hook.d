#!/bin/bash

set -euo pipefail

err() {
  echo -ne '\e[31m\e[1m' # Red + Bold
  echo -e "$@"
  echo -ne '\e[0m'
}

# This script will be copied into the .git/hooks directory, replacing the hook
# files such as pre-commit and pre-push. Once in place, this will execute each
# file in the various hooks/<name>.d/ directories.
script_dir=$(git rev-parse --show-toplevel)/hooks
hook_name=$(basename $0)

if [ "$hook_name" = "hook.d" ]; then
  echo "Don't run this script directly! Symlink it to .git/hooks/<name> instead!"
  exit 1
fi

hook_dir="$script_dir/$hook_name.d"
if [[ -d $hook_dir ]]; then
  for hook in $hook_dir/*; do
    if [ -x $hook ]; then
      echo "Running $hook"
      $hook "$@"

      exit_code=$?

      if [ $exit_code != 0 ]; then
        exit $exit_code
      fi
    else
      err "Not executable: $hook"
    fi
  done
fi

exit 0
