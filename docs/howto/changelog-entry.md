# Writing a changelog entry

Our changelog is [`docs/changelog.md`](../changelog.md).
It gets an entry for each release, written as part of the release
process. See [`docs/release.md`](../release.md).

Write the entry under the "Unreleased" heading.
`tools/bump-version` later stamps it with the release's
version number and date.

The entry doesn't have to be written all at once.
It works well to compile it incrementally: update the "Unreleased"
entry from time to time as PRs get merged, and then at release time
fill in just what's happened since the last update.
(See commits like "changelog: Update with latest changes".)

The entry's format is designed to make that incremental workflow
easy: because every change includes its PR number, the entry can
be compared directly against a decorated Git log or a GitHub list
of merged PRs. For more rationale, see commit 2b7ab49ff.

Start with the merge log (described below), so that its list of
user-visible changes can serve as the menu from which to select
the "Highlights for users".


## "Highlights for users"

This section becomes the release notes users see in the Play
Store and in TestFlight: the release process converts it with
`tools/format-changelog user`. (GitHub releases get the whole
entry, via `tools/format-changelog notes`.)

* Keep the section within 500 characters, the Play Store's limit
  for release notes. Count it with line-wrapping removed.
  (`tools/format-changelog` can't do the counting for a draft:
  it reads the latest stamped entry, skipping "Unreleased".)

* List only user-visible changes in the app's behavior, and only
  changes users might be happy to see. For example, dropping
  support for old OS or server versions is user-visible but isn't
  a highlight for users. It belongs in the merge log, like
  "Require iOS 16.0+" in the 30.0.273 entry.

* Order the items roughly by user impact, highest first.
  This is a judgment call. It's fine to do it imperfectly.

* Prefix an item with "(iOS)" or "(Android)" when the change
  affects only that platform.

* Usually, end each item with the issue number in parentheses,
  like "(#1972)". When there's no issue, use the PR number:
  "(PR #1902, toward #124)".

* If a translation sync from Weblate landed since the last
  release, and there's room under the character limit, consider a
  highlight for any languages with big increases in translation
  coverage, like "near-complete translations for German (de) and
  Italian (it)" in the 30.0.257 entry.

* If the release has other user-visible improvements beyond those
  listed, end the section with the line:

  ```
  * Too many other improvements and fixes to describe them all here.
  ```

  Skip that line when the bullets above it already cover
  everything user-visible in the release.


## "Highlights for developers"

Optionally start this section with bullets describing changes to
systems developers interact with: CI, the translation pipeline,
test infrastructure, tooling. See e.g. the "CI:" bullets in the
30.0.271 and 30.0.273 entries.

Then comes the merge log, with this heading:

```
* Merge log: PRs, with fixed issues and user-visible changes (earliest first).
```

(The "(earliest first)" label is new with this doc. Older entries
left the order implicit.)

The merge log has one item per PR merged since the previous
release, ordered by when they were merged, earliest first --
the same order the commits appear in main's history.


### Compiling the merge log

Use two complementary sources:

* GitHub: [the repo's closed issues sorted by recent
  update][gh-closed-issues] is a convenient filter,
  alongside the list of merged PRs.
  Or with the `gh` CLI:
  `gh pr list --state merged --search 'merged:>=DATE' --json
  number,title,mergedAt` lists merged PRs with their merge times,
  and each PR's `closingIssuesReferences` (a GraphQL field) gives
  the issues GitHub linked with a closing keyword -- the same
  "fix #N" list the merge log wants.

* Git: `git k` (Greg's alias for
  `git log --graph --oneline --decorate --boundary`, in homage to
  `gitk`; see [zulip-mobile's Git guide][zulip-mobile-git]).
  Commits appear decorated with refs like `pr/2079` when the PR
  was merged using `../zulip/tools/reset-to-pull-request` and
  `../zulip/tools/push-to-pull-request`, which record the PR
  under a `pr` pseudo-remote. PRs merged with GitHub's
  ["Rebase and merge" button][gh-rebase-merge] don't get these
  refs, so the GitHub lists are needed to fill those in.

Define "since the previous release" as the Git range
(`v30.0.273..main`), not a date filter. A GitHub search like
`merged:>=2026-06-24` double-counts: it includes PRs that were
merged late on the release date (in UTC) but before the
version-bump commit, and those already appear in that release's
entry. Cross-check against the tail of the previous entry's
merge log.

Because the log is ordered earliest first, new items go at the
end when updating an existing draft entry.

[gh-closed-issues]: https://github.com/zulip/zulip-flutter/issues?q=is%3Aclosed%20sort%3Aupdated-desc
[zulip-mobile-git]: https://github.com/zulip/zulip-mobile/blob/main/docs/howto/git.md
[gh-rebase-merge]: https://docs.github.com/en/pull-requests/reference/pull-request-merges#rebase-and-merge-your-commits


### Format of a merge-log item

* A PR that fixed no issue and made no user-visible change is
  just its number: `#2297`.

* When the PR fixed issues, say so with "fix", matching GitHub's
  closing keyword:

  ```
  * #2307: fix #773, fix #329.  Run iOS build in CI.
  ```

  Use "fix part of #N" or "fix most of #N" for partial fixes.

* When the PR made user-visible changes, describe them briefly --
  even when there's no linked issue:

  ```
  * #2305.  Require iOS 16.0+.
  ```

  This makes the merge log a convenient reference for questions
  like "when did we start requiring iOS 16?".


## Releases from a branch

When a release is cut from a branch that has changes not yet in
main, the entry distinguishes those changes, outside the
"for users" section. See "Preview releases" in
[`docs/release.md`](../release.md), and past entries mentioning
"experimental".
