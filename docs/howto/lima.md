# Developing in a Lima VM (macOS, experimental)

[`.lima/`](../../.lima/) in this repo holds a [Lima][lima] VM config
for developing Zulip Flutter on macOS, mainly as a sandbox for
running Claude Code. It's Chris's current setup, shared in case it's useful.

When run inside the VM, Claude Code sees only the files you mount into it,
and credentials you put there explicitly (e.g. a GitHub access token with
read-only scope). The VM is accessed with its own SSH keypair managed by Lima.

Anthropic documents several sandboxing approaches for Claude Code,
of varying weight. This setup uses a local VM; see
[howto/claude.md](claude.md#sandboxing) for the comparison.

[lima]: https://lima-vm.io/


## Workflow

Once set up, work splits across the host and the VM:

- **Build and run the app from the host.** `flutter run`,
  `flutter build`, Android Studio, etc. work as on a normal host
  Flutter install. The VM isn't involved.
- **Run Claude Code from the VM.** Claude will invoke `flutter analyze`,
  `flutter test`, `tools/check`, etc. inside the VM as it works. See
  [claude.md](claude.md) for Claude-specific tips.
- **Push from the host.** The VM's GitHub credential is read-only
  (see the [trust model](#trust-model) below), so `git push`
  happens on the host. Commits made in the VM are immediately
  visible on the host, since the clone is shared.

To enter the VM, run `limactl shell zulip-flutter` from your clone
dir on the host. It lands you at the same path inside the VM.
(Shorthand: add `export LIMA_INSTANCE=zulip-flutter` to your
`~/.zshrc` -- or `~/.bash_profile` if you're on bash -- then just
run `lima`.) To shut the VM down and bring it back later, use
`limactl stop zulip-flutter` and `limactl start zulip-flutter`.

Build state stays separate between the host and the VM:
`tools/provision-vm` bind-mounts VM-local copies over `.dart_tool/`,
`build/`, `android/.gradle/`, and `.flutter-plugins-dependencies`,
so each side keeps its own. There's no need to re-run
`flutter pub get` when you switch sides, and builds on the two
sides don't race on shared paths.


## First-time setup

### 1. Install Lima

```bash
brew install lima
```


### 2. Create your local config

Create `.lima/local.yaml` in your zulip-flutter clone, substituting
the path to your clone:

```yaml
base: zulip-flutter.yaml
mounts:
- location: "~/path/to/zulip-flutter"
  writable: true
```

`local.yaml` is gitignored; it references the committed
[`zulip-flutter.yaml`](../../.lima/zulip-flutter.yaml) and adds the
workspace mount.

**Important:** point the mount at the specific zulip-flutter clone --
**not** at `$HOME` or `~`. Pointing it higher up the tree would
expose your SSH keys, browser state, etc. to the VM.

Also note: anything in the mounted clone is visible inside the VM.
If your clone contains sensitive material such as a release-signing
key, even when it's normally encrypted at rest, a separate
clone for VM work is the simplest approach.


### 3. Start the VM

```bash
limactl start --name=zulip-flutter .lima/local.yaml
```

Select "Proceed with the current configuration".

On first start, downloads an Ubuntu 24.04 cloud image (~700 MB)
and takes a few minutes; subsequent starts are fast.


### 4. Set up Zulip Flutter inside the VM

Shell in (see [Workflow](#workflow) above for the command).
You're now in a clean Ubuntu environment with the workspace mounted.
Run:

```bash
tools/provision-vm
```

This installs the few needed system packages, clones the Flutter
SDK to `~/flutter` and adds it to your PATH (via `~/.profile`),
sets up the build-state bind mounts described in
[Workflow](#workflow) above, and fetches the app's dependencies.
It's idempotent, so re-run it if it fails partway.

Then open a fresh shell (or run `. ~/.profile`) and check that
`flutter test` passes.

(The VM needs no Android Studio or iOS tooling; the host handles
IDE and device runs.)


### 5. Install Claude Code

Inside the VM, install and authenticate Claude Code following Anthropic's
[install instructions](https://code.claude.com/docs/) for Linux.
See [claude.md](claude.md) for tips on using Claude in this repo.

The installer puts `claude` in `~/.local/bin` and may warn that
that's not in your PATH. There's no need for its suggested
`~/.bashrc` edit: the VM's stock `~/.profile` adds the directory
to the PATH now that it exists, so just open a fresh shell.


### 6. Optional: copy over your dotfiles

The VM starts as a stock Ubuntu bash environment. If you'll work
in it directly (not only through Claude), consider bringing over:

- Git config: your `user.name` and `user.email` (needed for
  committing from inside the VM, unless they're set in the
  clone's own `.git/config`), plus any aliases you're used to.
  Prune host-specific bits, like absolute paths into your host
  home directory. (The next step adds more to the VM's
  `~/.gitconfig`; if you ever replace that file wholesale,
  redo step 7.)
- Your shell prompt and other `~/.bashrc` customizations.

To copy a file from the host into the VM, `limactl cp` is handy:

```bash
limactl cp ~/some-file zulip-flutter:/tmp/
```


### 7. Authenticate `gh` and `git fetch`

The `gh` CLI (installed by `tools/provision-vm` in step 4) lets
Claude search and read public issues and PRs in the Zulip repos;
see [claude.md](claude.md#authenticating-gh) on why it's useful.
Authenticate it with a read-only personal access token:

1. Create a fine-grained PAT at
   <https://github.com/settings/personal-access-tokens/new>.
   For "Repository access" choose "Public Repositories (read-only)";
   no other permissions needed.

2. Inside the VM, run `gh auth login`:

   - host: `github.com`
   - protocol: `HTTPS`
   - "Authenticate Git with your GitHub credentials?": `Yes`
     (this lets `git fetch` share the token; see below)
   - "How would you like to authenticate?": `Paste an authentication token`
   - paste the token created above.

To rotate or remove the token, re-run `gh auth login` / `gh auth logout`.

The VM deliberately has no SSH credentials: the keypair Lima
manages is for the host to log in to the VM, and its private half
stays on the host. So `git fetch` fails on remotes with SSH URLs
(`git@github.com:...`), even for public repos. To make fetch
work, rewrite those URLs to HTTPS in the VM's global Git config:

```bash
git config --global url.'https://github.com/'.insteadOf 'git@github.com:'
```

Git then fetches over HTTPS, authenticated with the same token as
`gh`: the `Yes` above configures `gh` as Git's
[credential helper][git-credential-helper]. (If you answered `No`
there, run `gh auth setup-git` to get the same effect.) The
token's read-only scope is enforced by GitHub on the server side:
fetching public repos works, and a push is rejected with a 403.

Put this rewrite in the VM's `~/.gitconfig`, not the repo's own
config: the repo's config lives in the mounted workspace and is
shared with the host, which has its own SSH credentials and
should keep using them.

[git-credential-helper]: https://git-scm.com/docs/gitcredentials


### 8. Optional: clone the Zulip server repo

Some tasks go better when Claude can read the server's source:
researching server behavior the API docs don't yet answer, or
working on API documentation or design itself. The instructions
in [`.claude/rules/api.md`](../../.claude/rules/api.md) also
expect the server repo as a sibling of this one, for reading the
API changelog's source. Inside the VM:

```bash
sudo install -d -o "$(id -un)" -g "$(id -gn)" ../zulip
git clone https://github.com/zulip/zulip.git ../zulip
```

(The `sudo install` is because the parent directory, created by
Lima as scaffolding for the mount, is owned by root.)

The parent directory is VM-local disk (only this clone itself is
mounted from the host), so the server clone adds nothing to the
shared mount, and Claude can `git fetch` it to stay current.


## Trust model

The security boundary is the VM wall: Claude runs inside with
permission checks relaxed or off, and is treated as untrusted.

What the VM wall defends:

- **Host filesystem**: the VM sees only the mounted clone (or
  clones; see
  [Developing Flutter SDK changes](#developing-flutter-sdk-changes)).
  SSH keys, browser state, and everything else on the host are
  unreachable, and SSH agent forwarding is off (see
  [`zulip-flutter.yaml`](../../.lima/zulip-flutter.yaml)).
- **GitHub**: the VM's only GitHub credential is the read-only
  PAT from [step 7](#7-authenticate-gh-and-git-fetch) above;
  pushing happens from the host.

What this setup knowingly accepts:

- **The shared `.git/` is a host-execution path.** Git runs
  hooks and obeys config from `.git/`, which is in the mount and
  which `git diff` never shows: a planted `.git/hooks/` script
  would run as you, on the host, at your next host-side git
  command. Raise the bar by neutralizing per-repo hooks globally
  on the host:

  ```bash
  git config --global core.hooksPath ~/.config/git/hooks
  ```

  (an empty, or curated, directory). Not airtight -- the shared
  `.git/config` can re-point `core.hooksPath`, and a few config
  keys (e.g. `core.fsmonitor`) run commands themselves -- but
  what remains takes a targeted attack.
- **Network egress from the VM is unrestricted.** Anthropic
  [treats egress control as load-bearing][sandbox-environments]
  against prompt injection: an agent that reads a malicious web
  page or GitHub issue can leak anything it can read. Here that
  is little -- public code, work in progress, the public-read
  PAT, Claude's own credentials. (Enforcement would need a
  host-side packet filter; an in-VM firewall wouldn't bind
  against passwordless sudo. Worth revisiting if the VM ever
  holds anything sensitive.)
- **Files that steer future sessions** (`CLAUDE.md`, `.claude/`)
  are agent-writable. Most are tracked, so tampering shows up
  in `git diff`: treat unexplained diffs there as a red flag,
  not noise. Outside that audit: `.claude/settings.local.json`
  (gitignored yet shared, and can configure hooks -- a
  host-execution path like `.git/`, if you ever run Claude from
  this clone on the host), and Claude's VM-local state like
  memory (steers only VM sessions, which are untrusted anyway).

[sandbox-environments]: https://code.claude.com/docs/en/sandbox-environments


## Developing Flutter SDK changes

The setup for working on Flutter itself: a Flutter clone on the
host, mounted into the VM alongside the workspace. The clone's
source is shared between host and VM -- an edit made on either
side is visible on both -- while each side keeps its own
platform-specific build state (Linux binaries can't run on
macOS, nor vice versa). Inside the VM, the mounted clone
replaces the VM-local `~/flutter` from
[step 4](#4-set-up-zulip-flutter-inside-the-vm) as the Flutter
SDK.


### Add the mount

Clone Flutter on the host, and add it to `.lima/local.yaml` as a
second mount:

```yaml
mounts:
# ... the workspace mount ...
- location: "~/dev/flutter-for-jail"
  writable: true
```

If the VM instance already exists, editing `local.yaml` isn't
enough: the instance copied its config when it was created.
Stop the VM, apply the same change to the live config with
`limactl edit zulip-flutter`, and start it again. (`local.yaml`
still matters as the record for any future re-creation.)

Dedicate the clone to jail use, as the name in the example
suggests, rather than mounting a clone your other host work
relies on. The agent can write to the whole tree -- including
its `.git/`, a host-execution path like the workspace's (see
[trust model](#trust-model)) -- and the host's `flutter` tool
is built from whatever the tree contains. So review the agent's
SDK changes before running them host-side, as you would its app
changes; and above all, never build an app release with this
clone.


### Set up the VM side

In the VM's `~/.profile`, replace the Flutter PATH line that
`tools/provision-vm` added with one for the mounted clone's
`bin/`:

```bash
# Flutter SDK, host clone mounted into the VM
PATH="/Users/you/dev/flutter-for-jail/bin:$PATH"
```

Then, in a fresh shell, check that `type -p flutter` shows the
mounted clone, and re-run `tools/provision-vm`. (If the check
fails, the script would set `~/flutter` back up.)
Finding the mounted SDK on the PATH, the script skips cloning
its own, masks the SDK's build state with VM-local bind mounts,
as for the workspace (see [Workflow](#workflow)), and
bootstraps the Linux toolchain into the masked cache. Don't
run `flutter` in the VM before that point: with the masks not
yet up, it would write Linux artifacts into the shared tree.

The VM-local clone is then unused; reclaim the space with
`rm -rf ~/flutter`. On a fresh VM, put the PATH line in place
before first running `tools/provision-vm`, and there's no
`~/flutter` to clean up.


### Verify

Check `flutter test` passes in the VM. On the host, plain
`flutter` still uses your regular install; to run the app with
the modified SDK, invoke the clone explicitly, as in
`~/dev/flutter-for-jail/bin/flutter run`. The first such run
does the corresponding macOS-side setup; those artifacts land
in the clone's real directories, which the VM never sees
behind its masks. (A fork clone may
report `channel [user-branch]`; harmless. If version detection
ever misbehaves, see the workaround in `tools/lib/clone-flutter-sdk.sh`.)

To check that nothing escaped the masks, run
`git status --ignored=matching` in the SDK clone after
exercising `flutter` on both sides: apart from the masked
paths, the tree should stay clean. The masks cover framework
tests and `flutter update-packages`; those may also leave a
few harmless artifacts that are the same from either side
(per-package pub-workspace `.dart_tool/` shims, and coverage
data in `packages/flutter`). Expect SDK workflows we haven't
exercised to need more masks.


## Questions or trouble?

Ask in [`#mobile-dev-help`][mobile-dev-help] on chat.zulip.org.

[mobile-dev-help]: https://chat.zulip.org/#narrow/channel/516-mobile-dev-help
