# shellcheck shell=bash

# The root of the active Flutter tree.
#
# (This isn't strictly about Git, but in practice we use it
# mainly for `git -C`.)
flutter_tree() {
    local flutter_executable
    flutter_executable=$(readlink -f "$(type -p flutter)")
    echo "${flutter_executable%/bin/flutter}"
}
