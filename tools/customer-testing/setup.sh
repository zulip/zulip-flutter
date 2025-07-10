#!/usr/bin/env bash
# Setup script for running Zulip's tests as part of the Flutter
# "customer testing" suite:
#   https://github.com/flutter/tests

set -euo pipefail

# Flutter's "customer testing" suite runs in two environments:
#  * GitHub Actions for changes to the flutter/tests tree itself
#    (which is just a registry of downstream test suites to run);
#  * LUCI, at ci.chromium.org, for changes in Flutter.
#
# For background, see:
#   https://github.com/flutter/flutter/issues/162041#issuecomment-2611129958

if ! sudo -v; then
    # In the LUCI environment sudo isn't available,
    # but also the setup below isn't needed.  Skip it.
    exit 0
fi

# Otherwise, assume we're in the GitHub Actions environment.


# Install libsqlite3-dev.
#
# A few Zulip tests use SQLite, and so need libsqlite3.so.
# (The actual databases involved are tiny and in-memory.)
#
# Both older and newer GitHub Actions images have the SQLite shared
# library, from the libsqlite3-0 package.  But newer images
# (ubuntu-24.04, which the ubuntu-latest alias switched to around
# 2025-01) no longer have a symlink "libsqlite3.so" pointing to it,
# which is part of the libsqlite3-dev package.  Install that.
sudo apt install -y libsqlite3-dev
