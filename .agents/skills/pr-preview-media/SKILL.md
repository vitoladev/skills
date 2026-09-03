---
name: pr-preview-media
description: |
  Turn a frontend PR's browser-test CI artifact into GIFs + stills and embed
  them in the PR body's Preview section. Use after the e2e CI job goes green,
  when the task-orchestrator publish step names it, or when asked to put
  feature recordings into a PR.
---

# PR preview media

A reviewer reads the PR summary top to bottom and does not scroll into
comments — the recordings belong in the body, in a `## Preview` section near
the top. Everything runs on the host (gh, git, docker); nothing touches the
repo's command boundary or the product code.

## 1. Fetch the artifact

Find the green run for the PR's head branch and pull the recordings:

```bash
gh run list --branch <branch> --workflow <workflow.yml> --json databaseId,conclusion,headSha
gh run download <run-id> -n <artifact-name> -D <scratch>/e2e-artifact
```

The run must be green and its `headSha` must match the PR head — stale
recordings misrepresent the diff.

Videos land one per spec under the browser config's `outputDir`. When the e2e
command chains **several configs**, each has its own `outputDir` under a shared
results root, because Playwright empties `outputDir` on start-up and they would
otherwise erase each other. If a spec you expect is missing, check you are
looking under the right config's subdirectory before assuming it did not run.

## 2. Convert

When ffmpeg is not on the host, use its image. Per spec dir, one GIF and one
late-frame still — **two separate invocations**, since `-sseof` is an input
option and cannot share a command with the GIF output:

```bash
docker run --rm -v "$PWD/<spec-dir>:/in" -v <scratch>/media:/out linuxserver/ffmpeg \
  -y -i /in/video.webm -vf "fps=8,scale=640:-2:flags=lanczos" /out/<spec>.gif
docker run --rm -v "$PWD/<spec-dir>:/in" -v <scratch>/media:/out linuxserver/ffmpeg \
  -y -sseof -0.3 -i /in/video.webm -frames:v 1 -vf scale=800:-2 /out/<spec>.png
```

These settings keep each file in the tens of kilobytes. Eyeball one still
(Read the png) before publishing — a blank frame means the seek landed outside
the recording.

## 3. Before / after, when the PR changes an existing surface

A PR that reworks a screen, component or flow needs both states; a PR adding a
genuinely new surface says "New surface — no before state" and skips this. The
"before" must come from the **base branch**, never from cropping or re-staging
the after shot — the point is showing what a user loses as well as what they
gain.

Take it from the base branch's own green artifact where one exists. If the base
has no green run covering that spec, record it: check the base branch out in a
scratch worktree, run only the relevant spec, and pull the video from its
`outputDir`. Name the pair `<spec>-before.png` / `<spec>-after.png` and put
both through the same still command so the two frames are the same width.

## 4. Publish the media branch

Media rides an orphan branch named `pr-<n>-media`, never merged:

```bash
git worktree add --orphan -b pr-<n>-media <scratch>/media-branch
# copy media in, add a README naming the source run and "never merge"
git commit --no-verify -m "chore: preview media for PR #<n>"
git push origin pr-<n>-media && git worktree remove <scratch>/media-branch
```

`--no-verify` is deliberate: this is a media-only orphan branch, and the repo's
pre-commit hooks generally expect the toolchain that a media branch has no
reason to stand up.

## 5. Embed in the PR body

Edit the body with `gh pr edit <n> --body-file` — a comment is the wrong place.
The `## Preview` section carries: one `###` per feature state with its GIF, the
before/after table when step 3 applies, a `<details>` block with the stills, a
link to the CI run's artifact for full-res `.webm`, and the cleanup note
("media served from the never-to-be-merged `pr-<n>-media` branch; delete it
once this PR closes"). When `.github/PULL_REQUEST_TEMPLATE.md` already lays out
that shape, fill its placeholders rather than inventing a new one.

Image URLs MUST use the same-repo form
`https://github.com/<owner>/<repo>/raw/pr-<n>-media/<file>.gif`. On a private
repo `raw.githubusercontent.com` 404s for GitHub's image proxy and every image
renders blank; the `github.com/…/raw/…` form is rewritten into per-viewer
signed URLs and works for both visibilities.

Done when the PR body renders every image (spot-check the rendered page, not
just the markdown) and the section sits above the change description.
