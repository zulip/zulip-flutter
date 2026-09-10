# shellcheck shell=bash
#
# Shared library for the authorship suite in tools/check.

# Emails that mark a commit as machine-authored; extend as needed.
bot_emails=(
    'noreply@anthropic.com'    # Claude Code
)

# usage: bot_email_grep_args
#
# Print `grep -F` arguments matching any of $bot_emails, each
# framed in <>s so that only a whole address matches.
bot_email_grep_args() {
    local email
    for email in "${bot_emails[@]}"; do
        printf -- '-e\n<%s>\n' "${email}"
    done
}
