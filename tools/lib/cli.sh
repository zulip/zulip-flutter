# shellcheck shell=bash
#
# Shell functions for building CLIs (command-line interfaces).

# Run the given command, after printing the command for the user.
#
# This works by temporarily setting `set -x`.
run_visibly () {
    set -x
    "$@"
    { set +x; } 2>/dev/null
}
