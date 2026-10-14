# Triage evaluation criteria

This file defines **what** the PR triage bot checks. It is read from the
base branch to prevent contributors from modifying the criteria in their
own PRs. See `.github/workflows/pr-triage.yml` for **how** findings are
presented (comment format, tone, output structure).

Maintainers: edit this file to adjust evaluation criteria. The workflow
YAML should rarely need changes.

---

## Scope

This is structural triage, not code review. The checks below verify that
a PR meets the project's basic contribution requirements. They do not
evaluate code logic, implementation approach, correctness, or design —
that is the job of human reviewers.

---

## Checklist

### 1. Tests included

The project requires tests before detailed review can begin. A PR that
adds or modifies code but has zero changes in the `test/` directory
almost certainly fails this requirement.

- Docs: https://github.com/zulip/zulip-flutter#tests

### 2. Issue linkage and scope

Most Zulip PRs should reference a specific GitHub issue. If an issue is
referenced, the PR description should explain which parts of the issue
are addressed and which (if any) are left for follow-up. The code review
guide asks: "does the PR address all the points described in the issue?
If not, is it easy to tell which points are not addressed and why?"

Evidence of a problem: no issue reference at all, or scope is unclear.

- Docs: https://zulip.readthedocs.io/en/latest/contributing/code-reviewing.html

### 3. Commit structure

The core principle is "each commit is a minimal coherent idea."
Run `git log --oneline` on the PR's commits. Evidence of problems:

- Single "Update files" or "Fix bug" commits with large diffs
- Commit messages that don't explain *why* the change is being made
- The "feat: implement X" conventional-commit style — Zulip does NOT
  use conventional commits
- All changes lumped into one commit when they should be separate steps
- Refactoring mixed into the same commit as new features (Zulip expects
  refactoring in its own commits, ordered before the feature)

- Docs: https://zulip.readthedocs.io/en/latest/contributing/commit-discipline.html

### 4. No auto-formatting damage

Zulip does NOT use `dart format` or other auto-formatters. The README
explicitly warns about this. Evidence: widespread whitespace-only or
formatting-only changes to existing code in the diff.

- Docs: https://github.com/zulip/zulip-flutter#code-style

### 5. Translation strings

Applies only when the PR adds new user-visible strings in the UI. Check
whether they are set up for translation. Evidence: new hardcoded
user-facing strings that bypass the translation system.

- Docs: https://github.com/zulip/zulip-flutter#translations

### 6. PR description and self-review

Zulip uses a PR template with a self-review checklist. Evidence of
problems:

- The description claims features or changes that don't appear in the diff
- The description is generic boilerplate that could apply to any PR
- The description is missing entirely
- The self-review checklist is absent or perfunctorily completed (e.g.,
  "visual appearance" checked but no screenshots for a UI change)
- The PR description has been overwritten with LLM output instead of
  completing the template (the contributing guide explicitly warns
  against this)
- UI changes are present but no screenshots or screen recordings are
  included (check for changes to widget code or layout files)
- The linked issue or PR description mentions a discussion on
  chat.zulip.org but the PR doesn't cross-link to it

- Docs: https://zulip.readthedocs.io/en/latest/contributing/reviewable-prs.html

---

## AI use policy criteria

Zulip allows AI tools but has specific guidelines.
Full policy: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#ai-use-policy-and-guidelines

Key rules:

- Contributors must understand and be able to explain every change,
  whether or not AI was used.
- Changes must be split into coherent commits, not one AI-generated dump.
- AI-generated code comments that restate the code are considered noise.
  Zulip's philosophy: code should be "readable without explanation"
  rather than heavily commented.
- PR descriptions should be the contributor's own concise writing.
- Contributors should not trust LLM claims about how Zulip works.

Concrete evidence of policy violations:

- PR description or commit messages that misrepresent what the code
  actually does (compare stated claims to the actual diff)
- Verbose new code comments that restate what the code does in English
- Changes to files unrelated to the stated goal
- Generic variable/function renames dressed up as improvements. Zulip
  values names that are grepable and consistent with existing patterns,
  since "future developers will grep for relevant terms."
- Code that duplicates existing patterns instead of reusing them
- Boilerplate docstrings added where the project doesn't use them
- The PR description reads like LLM output: "Here's what I did:" /
  "Key changes:" / bullet lists of obvious statements /
  "This PR implements..." phrasing
- Code that makes incorrect assumptions about how Zulip works,
  suggesting LLM hallucination rather than reading the actual code
- Signs of "vibe coding" — the contributing guide explicitly says
  "fiddling or vibe coding until things seem to work, and then asking
  maintainers to verify code that you don't understand yourself, does
  not help the project." Indicators: shotgun changes across unrelated
  files, commented-out code left in, trial-and-error commit histories.

---

## Documentation reference

Available docs to link when flagging issues:

- First contribution guide: https://zulip.readthedocs.io/en/latest/contributing/contributing.html
- Submitting a PR: https://zulip.readthedocs.io/en/latest/contributing/reviewable-prs.html
- Commit discipline: https://zulip.readthedocs.io/en/latest/contributing/commit-discipline.html
- Code reviewing guide: https://zulip.readthedocs.io/en/latest/contributing/code-reviewing.html
- AI use policy: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#ai-use-policy-and-guidelines
- Chat with us: https://chat.zulip.org/#narrow/channel/mobile-dev-help
