#!/bin/sh -l

# TODO Reviewed ??-??-2026.

# Replace the wrapper with the container command so it receives signals and
# its exit status becomes the action's exit status.
exec "$@"
