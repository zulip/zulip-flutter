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

# Parses the Flutter version and commit-ID comment from pubspec.yaml.
#
# Output Parameters:
#   - flutter_version
#   - flutter_commit
pubspec_flutter_version() {
    local parsed
    # shellcheck disable=SC2207 # output has controlled whitespace
    parsed=( $(
        perl <pubspec.yaml -0ne '
             print "$1 $2" if (
                 /^  sdk: .*\n  flutter: '\''>=(\S+)'\''\s*# ([0-9a-f]{40})$/m)'
    ) ) || return
    if (( ! "${#parsed[@]}" )); then
        echo >&2 "error: Flutter version spec not recognized in pubspec.yaml"
        return 1
    fi

    # shellcheck disable=SC2034 # Output variable
    flutter_version="${parsed[0]}"
    # shellcheck disable=SC2034 # Output variable
    flutter_commit="${parsed[1]}"
}
