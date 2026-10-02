#!/usr/bin/env bash
# Setup script for running Zulip's tests as part of the Flutter
# "customer testing" suite:
#   https://github.com/flutter/tests
#
# Nothing to set up: since package:sqlite3 3.3.1 (86ba9e21c), a Dart
# build hook downloads and bundles libsqlite3 for `flutter test`, so
# the suite no longer needs a system SQLite installed.  The file
# stays as the suite's setup entry point, which flutter/tests invokes.

set -euo pipefail
exit 0
