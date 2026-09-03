---
name: create-pr
description: |
  Open this branch's pull request: body from the repo template, and preview
  media uploaded into the body itself with gh --attach. Use when invoked as
  /create-pr, when a branch has commits but no PR, or after gh stack puts a
  new layer on a stack.
---

# Create PR

Opens a PR that does not exist yet. `gh` and `git` run **on the host**;
nothing here goes through the repo's command boundary except the test
evidence in step 3.

Media goes **in the body** via `gh pr edit --attach`, which uploads a local
file to GitHub's own asset host and rewrites the path where the body already
references it. That replaces the `pr-<n>-media` orphan branch entirely — no
media branch, nothing to clean up when the PR closes. Step 4 gates on the `gh`
version and names the fallback.

## 1. Confirm the branch needs a PR

```bash
git branch --show-current
gh stack view --json 2>/dev/null    # empty/error when this is not a stack
gh pr view --json number,url,state 2>/dev/null
```

The current branch owns one PR. A `number` here means the PR already exists —
edit that body rather than opening a second one (`/maintain-pr-description`
owns that). Push first if the branch has unpushed commits; a PR opened on a
stale remote shows the wrong diff.

Never open a PR from the default branch. If `git branch --show-current` names
it, branch first.

For a stack, the base is the branch **below** this one in `gh stack view`,
never the default branch for an upper layer — that would swallow every layer
beneath it.

## 2. Open it

Stacked work goes through the `gh-stack` skill, opening one PR per layer
against the right base:

```bash
gh stack submit --auto
```

`--auto` is required — bare `submit` prompts per PR and blocks. `submit`
writes placeholder text, so the body is still step 3's job.

Off a stack:

```bash
gh pr create --base <default-branch> --title <t> --body-file <tmp>
```

## 3. Write the body

Start from `.github/PULL_REQUEST_TEMPLATE.md` when it exists and keep its
headings. Fill from the diff of this branch against **its** base:

```bash
git log --oneline <base>...HEAD
git diff --stat <base>...HEAD
```

Carry across, because a reviewer reads only this: the issue link, the stacking
note naming each layer and the reading order when there is a stack, and
evidence you actually observed — commands you ran with their real output, and
acceptance criteria each paired with the response that proves it. Run the
repo's checks through its command boundary, since that is often the only place
the toolchain resolves.

State a criterion the branch does not meet as blocked, and say what blocks it.
An unrun verifier, an invented coverage number, or a code-review verdict you
did not get costs the reviewer more than an admitted gap.

## 4. Fill the Preview section

Every PR touching a user-visible surface ships recorded proof of what it
changed: per surface, an MP4 when the proof is an interaction and a still when
a single frame carries it. A reviewer reads the summary top to bottom and
never scrolls into comments, so this is the only place they see the work run.

The media cannot exist when the PR is first opened — the recordings come from
a run of the branch — so open the PR with the section marked pending and
return here once you have files. `verify-frontend-output` drives the stack;
`pr-preview-media` records and converts what it leaves behind. Both run
locally: `--attach` uploads from disk, so nothing waits on CI, and a passing
verification is what makes the recording evidence.

### A changed surface carries before **and** after

Greenfield is the narrow case: a screen, component or flow this PR
introduces, which carries the after alone and says
`New surface — no before state`.

Everything a user could already reach is a changed surface and needs both
states. **Judge it per surface, not per PR:** a PR that adds a new screen and
also drops one control into an existing sheet has one greenfield surface and
one changed surface, and the changed one still owes a before. A field added to
a form, a new row action, a reworded empty state — each is a changed surface.
The point of the pair is showing what a user loses as well as what they gain,
which a single after shot cannot do.

`before` comes from the base branch — run the same scenario against a checkout
of it. Cropping or re-staging the after shot is not a before.
`pr-preview-media` has the mechanics: naming and matching widths.

### Attaching

`--attach` needs **gh 2.99.0 or newer**:

```bash
gh --version
```

Reference each file by its local path in the body markdown, then attach it.
Run `gh` **from the directory holding the media** so `./name.mp4` resolves;
GitHub uploads each file, rewrites that path to a
`github.com/user-attachments/assets/<uuid>` URL, and keeps the alt text:

```bash
# body contains:  ![checkout flow](./checkout.mp4) and ![events](./events-list.png)
gh pr edit <n> --body-file <tmp> \
  --attach './checkout.mp4' \
  --attach './events-list.png#Events list rendering three published events'
```

`--attach` repeats once per file, up to 50 per command.

**Video takes no alt text.** `--attach './flow.mp4#…'` fails with `cannot set
alt text on video`; pass the bare path. Write the body reference as
`![what it shows](./flow.mp4)` anyway — gh replaces the whole markdown with a
bare asset URL on its own line, which is what makes GitHub draw a player.
Images keep `![alt](url)`, so their `#` suffix is worth writing.

PNG, JPEG, GIF, WebP, SVG, MP4, MOV and WebM upload; images cap at 10 MB,
video at 10 MB on Free and 100 MB on paid plans. GitHub Enterprise Server does
not serve this yet. **A partial upload still rewrites the body**, so check
every asset in step 5.

Below 2.99.0, or on GHES, publish through
[`../pr-preview-media/media-branch-fallback.md`](../pr-preview-media/media-branch-fallback.md).

A PR with no user-visible surface — backend, infra, docs — replaces the whole
section with `Not applicable — no user-visible surface changes.` A diff that
touches the frontend and claims that line is wrong: find the surface it
changed.

## 5. Verify what a reviewer will see

```bash
gh pr view <n> --json number,url,title,baseRefName,body
```

Confirm each asset resolves rather than trusting the markdown — an attach that
partly failed still rewrites the body. **On a private repo the assets are
access-controlled and an anonymous fetch answers 404 for a perfectly good
file.** Do not read that as a failed upload. Check as the viewer does:

```bash
curl -s -o /dev/null -w '%{http_code} %{content_type}\n' -L \
  -H "Authorization: token $(gh auth token)" <asset-url>
```

Expect `200 image/png` or `200 video/mp4`.

Done when the PR is open against the right base; every surface the diff
touches appears in Preview, each changed one with both states and each
greenfield one saying so; every asset resolves as an authenticated viewer; and
a reviewer reading only the body would describe the same slice
`git diff <base>...HEAD` shows.
