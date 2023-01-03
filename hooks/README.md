# Git Hooks

## Using hooks

If you're just working on this repo, run `install-hooks.sh` and it'll get you
going!

## Writing hooks

Just stick your hooks in the appropriate .d-style folder - `pre-commit.d/`,
`pre-push.d/`, etc. Assuming they've run `install-hooks.sh`, they'll
automatically be picked up and run!

## New types of hooks

If you want to add a new type of hook, such as `pre-applypatch`, just make a
new .d folder (`pre-applypatch.d`) and re-run `install-hooks.sh`. It'll find
the new hook type and add the appropriate hook to git.

Every user will have to re-run `install-hooks.sh` as well, so please add new
hooks sparingly and with great fanfare. :)
