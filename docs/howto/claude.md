# Working with Claude Code

This doc collects practical tips for using Claude Code in this repo.

Setting up for the first time? Start with
[One-time setup](#one-time-setup) below: pick a sandbox to run
Claude in, and give it some helpful tools.


## The `.claude/` directory

[`.claude/`](../../.claude/) at the repo root holds project-level
Claude Code config (see Anthropic's [docs][claude-docs] for how
these files work):

- [`CLAUDE.md`](../../.claude/CLAUDE.md) -- the instructions
  Claude reads at session start.
- [`rules/`](../../.claude/rules/) -- detailed conventions for
  specific areas, split out from `CLAUDE.md` and referenced there.
- [`settings.json`](../../.claude/settings.json) -- permissions:
  which commands are pre-approved or denied. Mainly useful when
  running with permission checks on, where the allowlist spares
  you prompts; in a jail, the wall does the constraining and
  these are mostly moot.

These files are tracked like any other code, and improving them
is a contribution like any other. If you find ways to help
Claude work better here (a convention it keeps getting wrong,
say, or a permission worth pre-approving), please do send changes.


## Things to try

Claude is a language model driving tools in a loop: it reads and
writes code and prose, runs commands, and reacts to what comes
back. You can talk to it like you would a human (mostly): plain
natural language, context and goals included, corrections welcome
mid-task. The "mostly": each session starts fresh, knowing only
its training and what it reads here, and it can be confidently
wrong. So review its work like a new contributor's, and teach it
durably by putting anything you find yourself explaining twice
into [`.claude/`](#the-claude-directory).

That shape tells you where the leverage is: work that's checkable
(tests and the analyzer give Claude a fast feedback loop to run
on its own), work that's mostly breadth (searching and
cross-referencing this repo, the server's, and issues and PRs
via `gh`), and solid first drafts of tests and docs.

However you use it, Zulip's [AI use policy][ai-policy] applies:
you're responsible for understanding, testing, and being able to
explain whatever you submit.

[ai-policy]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#ai-use-policy-and-guidelines

A growing list of Claude Code features that have proven handy
in this project:

- `/code-review`: review the working tree's diff for bugs and
  cleanups, at a chosen effort level. Nice before sending a PR.
  `/review` covers similar ground as a lighter-weight option,
  in a fraction of the time.
- Plan mode (shift+tab): for a bigger task, Claude first explores
  the codebase and proposes a plan, and edits only once you've
  approved it. Cheap way to catch a wrong direction early.
- Research questions, like "how does X work?" or "when did the
  API start doing Y?": Claude can cross-reference this codebase,
  the server's (see [lima.md](lima.md#8-optional-clone-the-zulip-server-repo)
  on cloning it), and issues and PRs via `gh`.
- Paste a chat.zulip.org link: a small skill in this repo lets
  Claude fetch and read web-public conversations, like design
  discussions linked from issues.
- To discover more, run `/help` in a session, and see the
  [Claude Code docs][claude-docs].


## One-time setup

Two things to set up once: a sandbox for Claude to run in, and
some tools to make it more effective there.


### Sandboxing

A sandbox aims to wall Claude off from what it has no business
touching: your SSH keys, browser state, and the rest of your
filesystem beyond the project. That's partly defense: an agent
runs commands, and can be wrong, or steered by a malicious web
page or issue it reads. And it's partly leverage: the stronger
the wall, the more safely you can relax permission prompts and
let Claude work autonomously. The options differ in how much of
the wall they actually build:

- **Claude Code's built-in [Bash sandbox][bash-sandbox]** (`/sandbox`)
  uses Seatbelt (macOS) or bubblewrap (Linux) to constrain Bash
  commands. Lighter than a VM, but it only covers Bash. Built-in
  file tools, MCP servers, and hooks still run on the host with your
  identity, and Claude still shares your GitHub credentials and SSH
  keys via the host filesystem.
- The **[sandbox runtime][sandbox-runtime]** wraps the whole Claude
  process in Seatbelt (macOS) or bubblewrap (Linux), covering tools,
  MCP, and hooks. It can also enforce a default-deny network
  allowlist via a host-side proxy. Two catches: still beta as of
  2026-06 (v0.0.54, config may evolve), and because it runs on the
  host, isolation for reads is deny-then-allow: you enumerate paths
  to block (`~/.ssh`, etc.), so a missed entry is a leak. (Writes
  are the safer direction: denied except where allowed.)
- A **virtual machine**: the agent runs in a separate OS, seeing
  only files mounted in. Stronger default isolation than the
  host-level sandboxes (nothing on the host is reachable unless
  explicitly mounted), at the cost of VM overhead -- though with
  no egress restriction out of the box, unlike the sandbox
  runtime's proxy. This repo includes a [Lima](lima.md) config
  (for macOS hosts); see its [trust model](lima.md#trust-model).
- A **[dev container][claude-devcontainer]**, with caveats[^dev-container].
- **[Claude Code on the web][ccweb]** runs each session in an
  Anthropic-hosted VM. Useful for delegating tasks; this doc is about
  local development.

One risk is shared by every option that runs against the same
clone your host uses: `.git/` is a host-execution path. Git runs
hooks and obeys config from it, `git diff` never shows it, and a
jailed agent can write to it. See the
[Lima trust model](lima.md#trust-model) for details and a cheap
mitigation; they apply to the other options here too.

Anthropic's [sandbox environments page][sandbox-environments] covers
these approaches at a higher level.

[^dev-container]: Two caveats, as of 2026-06. JetBrains Gateway
    doesn't cover Android Studio, so for AS users the dev
    container's IDE-side draw isn't available. And VS Code's Dev
    Containers extension [always forwards the host's SSH agent
    into the container][issue-11413], with no way to opt out.
    That quietly hands the jailed agent the ability to
    authenticate as you anywhere your SSH key is trusted.

[sandbox-environments]: https://code.claude.com/docs/en/sandbox-environments
[bash-sandbox]: https://code.claude.com/docs/en/sandboxing
[sandbox-runtime]: https://github.com/anthropic-experimental/sandbox-runtime
[ccweb]: https://code.claude.com/docs/en/claude-code-on-the-web
[claude-devcontainer]: https://code.claude.com/docs/en/devcontainer
[issue-11413]: https://github.com/microsoft/vscode-remote-release/issues/11413


### Authenticating `gh`

GitHub's [`gh` CLI][gh] lets Claude (or you) read public issues
and PRs in the Zulip repos as structured JSON (much nicer than
scraping HTML), and authenticating lifts unauthenticated rate
limits. Install it where Claude runs (instructions at
[cli.github.com][gh]), and authenticate with a credential of the
narrowest scope that works. In a jail with its own environment,
like the Lima VM, that means a dedicated fine-grained PAT with
read-only access to public repos: GitHub then enforces
server-side that the agent can't push or read anything private.
The same token can also authenticate `git fetch` over HTTPS,
which such a jail needs, since it deliberately holds no SSH
keys. (The host-level options instead share your host's existing
`gh` and Git credentials; that's part of the wall they don't
build.)

For a worked example (creating the token, running
`gh auth login`, and the Git config for `git fetch`), see
[the Lima setup](lima.md#7-authenticate-gh-and-git-fetch).

[claude-docs]: https://code.claude.com/docs/
[gh]: https://cli.github.com/
