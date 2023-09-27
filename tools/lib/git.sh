# shellcheck shell=bash
#
# Shell functions for use with Git.

no_uncommitted_changes()
{
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
