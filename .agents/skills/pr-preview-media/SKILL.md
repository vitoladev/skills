---
name: pr-preview-media
description: |
  Turn a passing frontend verification into the MP4s and stills a PR's Preview
  section needs, and upload them into the body with `gh pr edit --attach`. Use
  after a frontend verification passes on this branch, when the
  task-orchestrator publish step names it, or when asked to put feature
  recordings into a pull request.
---

# PR preview media

A reviewer reads the PR summary top to bottom and does not scroll into
comments — the recordings belong in the body. `gh` uploads them there
directly; this skill is what gives it something true to upload. None of it
touches application code.

The source is a **passing verification run against a real stack**. Its
assertions are what make a recording evidence rather than decoration: a video
proves nothing on its own, and a screenshot of a screen nobody drove proves
less. Drive and assert first. If the run failed, there is no Preview to
publish — only a finding to report.

## Project bindings

- **Command boundary** — recording drives the browser, so it runs wherever the
  browser driver lives (commonly inside the repo's container). `ffmpeg`, `git`
  and `gh` run on the host. When the workspace is bind-mounted, a recording
  written under the repo from inside is already on the host for conversion;
  anything written to a container-only path is not.
- **Recording source** — the verification run's artifacts, or a scripted
  scenario driving the same flow.

## 1. Convert — match the medium to the claim

Pick the form from what the scenario actually proves, one per surface:

- **MP4** when the proof is an interaction and the order matters — a selection
  that routes somewhere, a signed-out action bouncing to login, a row leaving a
  tab after approval.
- **PNG** when a single frame carries it — an empty state, a rendered list, a
  form showing which options it offers, an error banner. **Reach for this
  first.** A reviewer reads a still instantly, and a video of a static screen
  spends their attention for nothing.

A before/after pair is two stills, whatever the surface does.

```bash
# Interaction -> MP4. yuv420p and +faststart make it play inline on GitHub;
# libx264 refuses odd dimensions, so round both down to even.
ffmpeg -y -i <in>.webm -an -c:v libx264 -pix_fmt yuv420p -movflags +faststart \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" <out>.mp4

# State -> a late frame. `-sseof` is an input option, so it needs its own run.
ffmpeg -y -sseof -0.3 -i <in>.webm -frames:v 1 -vf scale=800:-2 <out>.png
```

A `page.screenshot()` taken inline by the scenario is a better still than a
seeked frame: it is the moment the assertion passed, not whatever the
recording ended on.

**Read every png before publishing.** A blank frame means the seek landed
outside the recording — and two stills with the same hash mean the second
proves nothing the first did not. That is not always a bug: two routes that
render the same empty state produce honest identical frames, and a video is
the wrong medium for that claim. Check before publishing two of them as if
they showed different things:

```bash
shasum <a>.png <b>.png
```

## 2. Before / after, for every surface that already existed

Only a surface this PR **introduces** is exempt, and one PR often has both
kinds: a new screen plus one control dropped into an existing sheet is one
greenfield surface and one changed surface — the changed one still owes a
before.

The before comes from the **base branch**, never from cropping or re-staging
the after shot. Check the base out in a scratch worktree, bring the stack up
against it, and run the same scenario:

```bash
git worktree add <scratch>/base-shot <base-branch>
# launch + drive there, then take the still through the same command
git worktree remove <scratch>/base-shot
```

Name the pair `<name>-before.png` / `<name>-after.png` and put both through
the identical still command, so the two frames are the same width — a
reviewer comparing two differently-scaled screenshots reads the scaling as a
change.

## 3. Attach into the PR body

`gh pr edit --attach` uploads a local file and rewrites the body's reference
to point at the uploaded asset, so the media lives in GitHub's own attachment
store. No media branch, no raw URLs, nothing to clean up when the PR closes.

**Requires `gh` 2.99.0 or newer.** Check first; on anything older, or on
GitHub Enterprise Server, the flag does not exist and
[`media-branch-fallback.md`](media-branch-fallback.md) is the path.

```bash
gh --version
```

Reference each file by its **local path** in the body markdown, then attach
it. Run `gh` **from the directory holding the media** so `./name.mp4`
resolves:

```bash
# body contains:  ![checkout flow](./checkout.mp4) and ![events](./events.png)
gh pr edit <n> --body-file <body.md> \
  --attach './checkout.mp4' \
  --attach './events.png#Events list rendering three published events'
```

- Alt text follows the path after `#`. Without it the filename is used.
- **Video takes no alt text** — `--attach './flow.mp4#…'` fails. Write the
  markdown reference `![what it shows](./flow.mp4)` anyway; gh replaces the
  whole reference with a player.
- An attachment the body does not reference is appended to the end instead.
- PNG, JPEG, GIF, WebP, SVG, MP4, MOV and WebM upload; images cap at 10 MB,
  video at 10 MB on Free and 100 MB on paid plans. GitHub Enterprise Server
  does not serve this yet.
- `--attach` repeats once per file, up to 50 per command.
- Without a body flag, the PR keeps the body it has and attachments are
  appended.
- On a partial failure the PR is still updated with what succeeded, and the
  command exits non-zero — so check the status, not just the printed URL.

## 4. Verify what rendered

Confirm each asset resolves rather than trusting the markdown — a partial
upload still rewrites the body. **On a private repo the assets are
access-controlled and an anonymous fetch answers 404 for a perfectly good
file**, so check as the viewer does, with credentials:

```bash
gh pr view <n> --json body -q .body \
  | grep -o 'https://github.com/user-attachments/assets/[^)[:space:]]*' \
  | while read -r u; do
      curl -s -o /dev/null -w "%{http_code} %{content_type} $u\n" -L \
        -H "Authorization: token $(gh auth token)" "$u"
    done
```

Expect `200 image/png` or `200 video/mp4` per asset. Done when every surface the diff touches carries the
form its proof needs — MP4 for an interaction, a still for a state; every
surface that already existed also has a before from the base branch at the
same width; and every asset resolves in the rendered page.
