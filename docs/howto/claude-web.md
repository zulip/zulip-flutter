# Developing with Claude Code on the web

[Claude Code on the web][ccweb] runs each Claude session in an
Anthropic-hosted VM, cloned fresh from the repo. It's useful for
delegating tasks without tying up a local machine. Sessions can
be started and steered from [claude.ai/code][claude-code-web]
in a browser, or from the Claude mobile app's Code tab (see the
[quickstart][ccweb-quickstart]). To use it for this repo, do
the [one-time setup](#one-time-setup), then follow the
[session workflow](#session-workflow). Read the
[limitations](#limitations--rough-edges) too, before relying
on it.

The tips in [claude.md](claude.md) apply in cloud sessions too;
that doc also [compares](claude.md#sandboxing) this with the
local sandboxing options.

[ccweb]: https://code.claude.com/docs/en/claude-code-on-the-web
[ccweb-quickstart]: https://code.claude.com/docs/en/web-quickstart
[ccweb-connect]: https://code.claude.com/docs/en/web-quickstart#connect-github
[ccweb-troubleshoot]: https://code.claude.com/docs/en/web-quickstart#troubleshoot-setup
[ccweb-start]: https://code.claude.com/docs/en/web-quickstart#start-a-task
[claude-code-web]: https://claude.ai/code


## One-time setup

You'll need a Claude plan that includes Claude Code on the web
(Pro, Max, or Team), and a fork of zulip-flutter on GitHub. If
you don't have a fork: signed in to GitHub, press "Fork" near
the top of [zulip/zulip-flutter][upstream-repo] and accept the
defaults ([GitHub's guide][fork-a-repo] has more). You'll run
web sessions on your fork, not on zulip/zulip-flutter.

1. **Connect GitHub.** At [claude.ai/code][claude-code-web],
   sign in (choosing "Continue on web" if offered the desktop
   app instead), then follow the prompt to sign in with GitHub
   and approve the authorization. If asked to install the
   Claude GitHub App, you can skip it; it enables only the
   "Auto-fix" feature, which isn't needed. If onboarding then
   shows a "Create your first cloud environment" form, keep its
   defaults and finish; the next step covers what that was
   about, and adds a second one set up for this repo.

   > [!TIP]
   > If the GitHub sign-in shows "GitHub access is required"
   > and no button, an Owner of your Claude organization must
   > first turn on the GitHub connector (Admin settings >
   > Connectors); ask them, then reload the page and start over.
   >
   > If it otherwise doesn't go as described, the quickstart's
   > [Connect GitHub][ccweb-connect] steps and its
   > [troubleshooting][ccweb-troubleshoot] section cover the
   > variations (no repositories listed, only a login button,
   > and so on).

2. **Create an environment** for this repo. An environment is
   a saved configuration for sessions: network access,
   environment variables, and a setup script that runs when a
   new session starts. On [claude.ai/code][claude-code-web],
   open the environment selector, the cloud icon in the row
   above the message box (it shows the current environment's
   name, "Default" so far), and choose "Add cloud environment".
   In the dialog:

   - **Name**: something you'll recognize in that selector,
     such as `zulip-flutter`.

     The script runs once per build of the environment's cache,
     which takes about three minutes (observed 2026-09): at your
     first session in the environment, and again whenever the
     cache expires, roughly weekly. Sessions in between start in
     seconds.

   - **Network access**: "Custom", with "Also include default
     list of common package managers" checked, and two allowed
     domains:

     - `chat.zulip.org`, for reading chat threads linked from
       issues and PRs;
     - `zulip.com`, for reading API docs.

     (Without the default list, the setup script fails with 403s
     from apt, the Ubuntu archives included.)

   - **Environment variables**: none needed.

   - **Setup script**: paste this one line:

     ```bash
     /home/user/zulip-flutter/tools/provision-cloud
     ```

     (If your fork isn't named `zulip-flutter`, adjust the path
     to match.) The script installs the system packages and the
     Flutter SDK, warms the pub cache, and clones the Zulip
     server repo to `../zulip`.

[upstream-repo]: https://github.com/zulip/zulip-flutter
[fork-a-repo]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo


## Session workflow

1. **Sync your fork** when it's been a while. Sessions build
   on the fork branch you pick, and your fork's `main` doesn't
   track upstream's by itself. A stale branch means stale code
   (so stale answers) and stale Claude config. GitHub's
   ["Sync fork" button][sync-fork] does it, or a Git alias like

   ```bash
   git config alias.sync-fork \
       '!git fetch upstream && git push me upstream/main:main'
   ```

   (adjust to your remote names), making it one command:
   `git sync-fork`.

2. **Start the session** at [claude.ai/code][claude-code-web]
   or in the mobile app's Code tab: pick your fork and branch,
   the environment you created in [One-time setup](#one-time-setup)
   (via the same cloud icon), and a permission mode, and
   describe the task (the quickstart's
   [Start a task][ccweb-start] walks through the controls).
   The session clones that branch, runs the
   SessionStart hook (see [How it works](#how-it-works)), works
   on the branch, and pushes to it when it reaches a stopping
   point. The first session in a new environment takes a few
   minutes to start while the setup script runs (see
   [One-time setup](#one-time-setup)); later sessions start from
   the cached result in seconds, until the cache expires and the
   next start rebuilds it.

3. **Follow along.** A session is a chat like any other: read
   Claude's replies, answer its questions, and send follow-ups
   to steer it, or step away and come back when it's done. If
   it changes code, the diff view shows the changes so far;
   you can comment on specific lines there, and the comments
   queue up and go to Claude along with your next chat message.

If you only wanted answers, you're done. The rest applies when
the session wrote commits you want to send in a PR.

4. **Receive the handoff.** A session's work comes back to you
   to finish, not straight to review. It may open a pull
   request, but only ever a **draft** one: the commits are
   Claude's, and a draft says the work still needs a human (see
   [Trust model](#trust-model)). Taking it the rest of the way
   is local, in the steps below.

5. **Test it yourself**, when the change calls for it. The
   cloud VM has no device or emulator, so this has to be done
   on your machine. [Teleport][teleport] the session there:
   `claude --teleport` offers a picker of your sessions (or
   copy the exact command from the session's menu on the web,
   "Open in > Terminal"). That checks out the session's branch
   and brings the conversation along. Then run the app as
   usual; see the [README](../../README.md).

6. **Take authorship** of the commits, in that same checkout.
   Neither teleporting nor `git cherry-pick` changes an author,
   so amend each commit that's Claude's with `--reset-author`.

7. **Send the PR.** If the session opened a draft PR, mark it
   ready for review on GitHub once you'd stand behind it (per
   Zulip's [AI use policy][ai-policy]). If it didn't, open one
   yourself.

[sync-fork]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork
[teleport]: https://code.claude.com/docs/en/claude-code-on-the-web#from-web-to-terminal


## Limitations / rough edges

- The VM has no device or emulator, so the app can't be run
  there. Manual testing means teleporting the branch to your
  machine; see the [session workflow](#session-workflow).

- The VM's network is allowlisted: commands Claude runs there
  reach the default package registries, GitHub, and the domains
  added in setup, and nothing else. (Claude's WebFetch tool is
  unaffected, since that tool fetches from outside the VM;
  checked 2026-07.) If a task needs another site, add its
  domain to the environment, and consider adding it to the
  setup instructions above.

- Claude can't read everything on `zulip/zulip-flutter` from a
  session: GitHub API access is scoped to your fork (a GitHub
  token of your own doesn't change that), so upstream issues
  and PRs reach it only by some routes, and issue comments by
  none (checked 2026-07). When a comment thread matters, paste
  it into the session. Details: [claude-code#78277][cc-78277].

- `flutter test` needs a workaround, which Claude applies on its
  own: the proxy blocks one package's download of a prebuilt
  library ([claude-code#78330][cc-78330]), so CLAUDE.md has
  Claude use the system library instead, via a pubspec.yaml
  edit it keeps out of commits.

[cc-78277]: https://github.com/anthropics/claude-code/issues/78277
[cc-78330]: https://github.com/anthropics/claude-code/issues/78330


## Trust model

Unlike the [Lima setup](lima.md#trust-model), where pushing is
reserved for the host, cloud sessions are designed to push:
Anthropic's GitHub proxy holds your real credentials outside
the sandbox, and hands the session a credential scoped to your
fork (pushing a new branch there worked, 2026-09). Since
sessions push, they run on a fork even for those with push
access upstream: scratch branches don't belong there. Review
anything it produces like any other contributor's work, and
test it yourself where the change calls for it, since the
session can't run the app. See Zulip's
[AI use policy][ai-policy].

Commits made in a session are created with Claude as the
author and committer (`noreply@anthropic.com`), not your name,
and you're expected to take authorship at the moment you're
ready to stand behind the commits, before sending a non-draft
PR (see [session workflow](#session-workflow)), which leaves
Claude credited in a Co-Authored-By trailer.

(Commits are also unsigned: the container would sign them as
Anthropic's `claude` GitHub identity, but the session-start
hook turns that off, since the signature would stop meaning
anything once you take authorship.)

[ai-policy]: https://zulip.readthedocs.io/en/latest/contributing/contributing.html#ai-use-policy-and-guidelines


## How it works

The setup script runs once, as root, when the environment's
cache is first built; Anthropic then snapshots the filesystem
and starts later sessions from the snapshot. The cache is
invalidated when the setup script or network settings change,
and when it expires after roughly seven days; the next session
start then rebuilds it. Only the setup script's work gets
snapshotted: anything downloaded during a session (pub
packages, Flutter artifacts) is not, which is why the setup
script warms those caches up front.

Two notes on maintaining your environment:

- The setup-script field invokes the script by absolute path,
  so the script can find the checkout from its own location;
  the working directory it's started in isn't reliably the
  checkout (observed 2026-07).
- The cache is keyed on the field's text (and the network
  settings), not on the script's contents. So when
  `tools/provision-cloud` changes in the repo, your environment
  keeps the old script's results until the cache expires or you
  force a rebuild by changing the field, e.g. by adding or
  bumping a `# v2` comment after the command.

Each session then starts from a fresh clone of the repo, plus
that snapshot, and runs a SessionStart hook,
[`tools/cloud-session-start`](../../tools/cloud-session-start)
(configured in [`.claude/settings.json`](../../.claude/settings.json)).
The hook:

- if it was started on upstream rather than a fork, tells Claude
  to stop and have you restart on your fork (a SessionStart hook
  can't hard-halt a session, so it warns via context);
- turns off commit signing, which would otherwise sign as
  Anthropic's `claude` identity (see [Trust model](#trust-model));
- fetches your fork's `main` and unshallows the clone, which
  starts out shallow and single-branch, so that `tools/check`
  can find the branch's merge-base;
- runs `flutter pub get` for the fresh clone (fast, thanks to
  the snapshot's warm pub cache), showing the output on failure
  so Claude can react, say with `flutter upgrade` when the
  cached SDK has fallen behind `pubspec.yaml`.

The hook is a no-op outside cloud sessions (it checks
`CLAUDE_CODE_REMOTE`), so local and Lima-VM sessions are
unaffected.


## Questions or trouble?

Ask in [`#mobile-dev-help`][mobile-dev-help] on
[chat.zulip.org][czo].

[czo]: https://zulip.com/development-community/
[mobile-dev-help]: https://chat.zulip.org/#narrow/channel/516-mobile-dev-help
