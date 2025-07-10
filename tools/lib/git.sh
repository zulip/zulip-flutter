# shellcheck shell=bash
#
# Shell functions for use with Git.

no_uncommitted_changes()
{
    # This line ensures the checks below are working from up-to-date data.
    # Empirically it seems rarely if ever necessary on Linux,
    # but does come up on macOS and Windows.
    git update-index -q --refresh || return

    if ! git diff-index --quiet --cached HEAD -- "$@"; then
        # Index differs from HEAD.
        return 1
    fi
    if ! git diff-files --quiet -- "$@"; then
        # Worktree differs from index.
        return 1
    fi
}

no_untracked_files()
{
    if git ls-files --others --exclude-standard -- "$@" \
            | grep -q .; then
        return 1
    fi
}

git_status_short()
{
    # --untracked-files=normal is the default; but the user's local config
    # may have overridden it, so we specify explicitly.
    git status --short --untracked-files=normal -- "$@"
}

# shellcheck disable=SC2120  # parameters are all optional
check_no_uncommitted_or_untracked()
{
    local problem=""
    if ! no_uncommitted_changes "$@"; then
        problem="uncommitted changes"
    elif ! no_untracked_files "$@"; then
        problem="untracked files"
    else
        return 0
    fi

    local qualifier=
    if (( $# )); then
        qualifier=" in $*"
    fi
    echo >&2 "There are ${problem}${qualifier}:"
    echo >&2
    git_status_short "$@"
    echo >&2
    echo >&2 "Aborting, to avoid losing your work."
    return 1
}

# Compute what remote name is being used for the upstream repo.
git_upstream_remote_name() {
    # Out of the names listed by `git remote`, pick one from the
    # list below, in preference order.
    grep -m1 -xFf <(git remote) <<EOF
upstream
origin
EOF
}

git_upstream_ref() {
    echo refs/remotes/"$(git_upstream_remote_name)"/main
}

# usage: git_base_commit [TIP [UPSTREAM]]
#
# The merge-base of TIP (default: current HEAD) with
# UPSTREAM (default: upstream/main or origin/main).
git_base_commit() {
    tip_commit=${1:-@}
    upstream=${2:-$(git_upstream_ref)}
    git merge-base "$tip_commit" "$upstream"
}

# usage: git_changed_files [DIFFARGS..]
#
# Lists files that have changed, excluding files that no longer exist.
#
# Arguments are passed through to `git diff`.
git_changed_files() {
    git diff --name-only --diff-filter=d "$@"
}

# The root of the active Flutter tree.
#
# (This isn't strictly about Git, but in practice we use it
# mainly for `git --git-dir`.)
flutter_tree() {
    local flutter_executable
    flutter_executable=$(readlink -f "$(type -p flutter)")
    echo "${flutter_executable%/bin/flutter}"
}
