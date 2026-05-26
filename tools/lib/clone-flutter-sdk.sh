# shellcheck shell=bash

# Clone the Flutter SDK to a given directory.
#
# Arguments:
#   $1: target directory (e.g., ~/flutter)
clone_flutter_sdk() {
    local flutter_tree="$1"

    # Upstream's version calculation fails with a shallow clone,
    # so instead clone with `--filter=blob:none`.
    git clone --filter=blob:none -b main \
        https://github.com/flutter/flutter "$flutter_tree"

    TZ=UTC git -C "$flutter_tree" log -1 \
        --format='%h | %ci | %s' --date=iso8601-local

    # The Flutter tool assumes the tip of tree is "origin/master"
    # (or "upstream/master"):
    #   https://github.com/flutter/flutter/issues/160626
    # TODO(upstream): make workaround unneeded
    git -C "$flutter_tree" update-ref refs/remotes/origin/master origin/main
}
