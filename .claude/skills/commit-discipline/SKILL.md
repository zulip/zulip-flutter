---
name: commit-discipline
description: "Conventions for commits in this repo — how to split and order them, summary-line format, the [nfc] marker, the Fixes line, and body content. Use whenever writing, structuring, amending, or splitting commits: before running `git commit`, when rewording, or when preparing commits for a PR."
---

# Writing commits

- **Summary line is `prefix: Sentence`** —
  the prefix is 1–2 lowercase words naming the part of the codebase
  (e.g. `compose:`, `api:`, `action_sheet:`), then a complete sentence
  in the imperative mood ("Add", "Fix", "Rename" — not "Added"/"Fixing"),
  capitalized, with no period at the end.
  For a commit that only touches tests, append ` test` to the prefix
  (e.g. `msglist test:`).
  Keep the whole line ≤ 72 characters, and leave out self-evident
  details like "update tests" or "update docs".
  Never use a generic prefix like `bug:`, `fix:`, or `refactor:`.
  For recent examples, see `git log`.

- **Mark pure refactors with `[nfc]`** —
  when a commit is intended to have no effect on how the code behaves
  (a preparatory refactor, rename, or code move),
  append ` [nfc]` — "no functional change" — to the prefix:
  `compose_box [nfc]: Extract _fileFromXFile helper`.
  This lets a reviewer see at a glance which commits in a series
  carry the actual change in behavior.

- **Closing an issue** —
  make `Fixes #NNNN.` the **first line of the body**, right after the
  summary's blank line.
  Never write "Partially fixes #NNNN"; use `Fixes part of #NNNN.` instead.

- **Body explains why and how, not what** —
  separate it from the summary with a blank line,
  and line-wrap to about 68 characters (max 70; links may run longer).
  Give the context and motivation a reviewer needs to verify the change
  is correct and safe. Don't restate the diff (changed files, "updated
  tests") or narrate your process ("First I tried X").
  Many commits need no body at all; omit it when the summary
  (plus a Fixes line) already tells a reviewer everything they need.

- **Each commit is one minimal coherent idea** —
  it must pass tests on its own, so test updates ride in the same commit
  as the change they cover.
  It shouldn't make the app worse or introduce a regression: each commit
  should be safe to land on its own (or explain in the body why not), and
  earlier commits must still work if a later one in the PR is dropped.
  Split preparatory refactors, renames, and code moves into their own
  commits *before* the feature commit; don't bundle unrelated changes.
  A feature needn't split into one commit per subfeature; when in doubt,
  err toward smaller commits — easy to squash later, not vice versa.
  Fix a broken commit by amending it, not by stacking a "fix tests" commit.

- **Don't churn within a PR** —
  don't add content in one commit only to remove or move it in a later
  one; plan upfront what belongs where.
  Leave no debugging code, commented-out code, or temporary TODOs behind.

- **Crediting other contributors** — when a commit includes work by
  someone other than you (e.g. continuing another person's branch),
  credit them with a `Co-authored-by: Name <email>` trailer after a
  blank line. (This is separate from the `Co-Authored-By: Claude …`
  trailer added automatically.) Don't put `@`-mentions in commit
  messages.
