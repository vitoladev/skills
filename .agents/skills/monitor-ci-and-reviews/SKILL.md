---
name: monitor-ci-and-reviews
description: |
  Watch a pull request's checks and incoming review until they settle, then
  triage what came back. Use when invoked as /monitor-ci-and-reviews, after
  pushing to a PR branch, or when asked to wait for CI, for a review, or for a
  PR to go green.
---

# Monitor CI and reviews

Waiting is the work: a check that flips red twenty minutes from now matters as
much as one that is red already. Arm a watch, keep working, and triage what
lands. `gh` runs on the host.

## 1. Resolve the branch and its base

```bash
git branch --show-current
gh stack view --json 2>/dev/null    # empty/error when this is not a stack
```

The current branch owns one PR. In a stack, a layer is only green when every
layer **below** it is green too — a red base makes this layer's pass
meaningless, so watch both. Read the whole stack's PR numbers out once, here.

## 2. Know what checks to expect

**Discover the checks; do not assume one.** Workflow files are not the whole
list — GitHub Apps (review bots, coverage, preview deploys) post checks
independently of any workflow in the repo, so a check can arrive that no YAML
in the tree declares. Read what actually reports:

```bash
gh pr checks <n> --json name,bucket,workflow
ls .github/workflows/
```

Build the expected set from a previous run on the same base rather than from
the YAML alone. **Do not conclude from a workflow's triggers that nothing will
come** — an app-posted check has no trigger you can read.

A red check from a review bot is usually *not* a build failure. Read its
summary: "outstanding review feedback" means go read the review (step 5), not
hunt for a failing job.

**The `paths-ignore` trap.** A workflow carrying `paths-ignore` (commonly
`['**.md']`) means a diff touching only those paths triggers **no run at all**.
That is not "still pending"; it is "nothing will ever report". Check what the
diff touches before concluding a PR is stuck:

```bash
[ "$(git diff --name-only <base>...HEAD | grep -cv '\.md$')" -gt 0 ] \
  && echo "CI will run" || echo "markdown-only: no CI run expected"
```

**Do not write this as `grep -qv`.** Where `grep` is ugrep, `-q` returns the
wrong exit status combined with `-v`: it reported "markdown-only" for a diff
containing twenty non-markdown files while CI was demonstrably running.
`grep -cv` and a numeric comparison are reliable everywhere.

## 3. Arm a watch per PR

One watch per PR, emitting each check as it reaches a terminal state and
exiting when all of them have:

```bash
prev=""
for i in $(seq 1 80); do
  s=$(gh pr checks <n> --json name,bucket 2>/dev/null || echo '[]')
  cur=$(jq -r '.[] | select(.bucket!="pending") | "PR<n> \(.name): \(.bucket)"' <<<"$s" | sort)
  comm -13 <(echo "$prev") <(echo "$cur")
  prev=$cur
  jq -e 'length>0 and all(.bucket!="pending")' <<<"$s" >/dev/null && { echo "PR<n> SETTLED"; break; }
  sleep 30
done
```

`bucket` is `pass` / `fail` / `skipping` / `cancel` / `pending`, so selecting
everything that is not `pending` reports failures and cancellations as loudly
as passes. A filter matching only `pass` goes silent on a red run, and silence
is indistinguishable from still-running.

`length>0` guards the first seconds after a push, when the checks array is
empty and `all()` is vacuously true — without it the watch exits immediately
and reports green before a single job has started. Note this same guard is
what makes the no-run case in step 2 spin to the full 80 iterations rather
than exiting: recognise it from the diff, not from the watch.

Poll at 30s or slower; `gh` shares the GitHub API rate limit with everything
else in the session. Then keep working — the notification arrives on its own.

## 4. Read the state, not the label

```bash
gh pr view <n> --json mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
```

`mergeStateStatus` is `CLEAN` when it is ready, `UNSTABLE` while checks run,
`BEHIND` when the base moved, and `DIRTY` for conflicts. **It is computed
lazily**: straight after a push it can still describe the previous head, and a
`DIRTY` that contradicts a clean local

```bash
git merge-tree --write-tree <base> HEAD
```

is stale rather than true. This one costs real time — a PR can report
`CONFLICTING` for a base branch that is already an ancestor. Re-read it before
believing it.

`reviewDecision` **survives a force-push**, so an `APPROVED` may predate the
commits under review. Trust the review whose `submittedAt` is later than the
current head SHA, or a bot's own check run — not the summary field.

## 5. Triage what settled

**A red check.** Pull the failing step rather than guessing from the name:

```bash
gh run view <run-id> --log-failed
```

Reproduce it locally through the repo's own gates before editing, routing the
commands through the repo's command boundary when it has one. Commit the fix
on the branch that owns the code, which for a stack is often below the layer
that went red.

**A stale body.** Fixes pushed while waiting make the description lie. Repair
it with `/maintain-pr-description`, and re-check that Preview media still
matches what the branch now does — a recording of superseded behaviour is
worse than none.

Re-arm the watch after every push. A fix is not green until its own run says
so, and reporting the previous run's pass as the current state is the one
failure this skill exists to prevent.

## 6. Report

Give the per-check result for each layer, the merge state, whether any review
is current with the head SHA, and what is left to do. Name anything still
pending as pending rather than rounding it to green — and name a PR whose diff
triggers no run as "no CI expected" rather than as either.

Done when every check on this branch and every layer below it has reached a
terminal state (or is correctly identified as one that will never run), each
red one is fixed or explained, and the reported state matches what
`gh pr checks` prints right now.
