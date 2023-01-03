#!/bin/bash

set -euo pipefail

# Figure out which hooks we want to install
OUR_HOOK_DIRECTORY=$(dirname $0)
GIT_HOOK_DIRECTORY=$(realpath $OUR_HOOK_DIRECTORY/../.git/hooks/)
for hook in $(find $OUR_HOOK_DIRECTORY -type d -name '*.d'); do
  HOOK_NAME=$(basename $hook)
  HOOK_NAME=${HOOK_NAME::-2}

  echo "Installing hooks for $HOOK_NAME to $GIT_HOOK_DIRECTORY/$HOOK_NAME..."
  ln -sf ../../hooks/hook.d "$GIT_HOOK_DIRECTORY/$HOOK_NAME"
done
