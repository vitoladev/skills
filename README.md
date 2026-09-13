# vitola-skills

Project-agnostic skills and agents for taking a feature from spec to merged
stack: scope the tickets, drive each slice through implement → verify →
review → publish, and keep the PRs honest afterwards.

Nothing here hardcodes a repo. Each skill and agent opens with the bindings
it needs — issue tracker, package commands, verify routes, review standards,
command boundary — and resolves them at run time. An unresolvable binding is
reported, never guessed.

## What's inside

**Orchestration**

| | |
|---|---|
| `ticket-scoping` | PRD/spec → parent issue + backend/frontend/contract/infra sub-issues, each with numbered requirements and a pressure-tested plan |
| `task-orchestrator` | Drives one parent issue to a published stack in the calling session, gating every slice through verify → commit → review; checkpoints every phase so a killed run resumes where it stopped (`/task-orchestrator resume <id>`) |
| `backend-executor` / `frontend-executor` *(agents)* | Implement one slice each, carrying the code quality rules inline; never delegate |
| `backend-verifier` / `frontend-verifier` *(agents)* | Prove one slice's acceptance criteria with executed requests or a real browser; never fix |
| `code-reviewer` *(agent)* | Standards + Spec review of one slice's diff in one context; P0–P3 with a verdict |
| `committer` *(agent)* | Owns the gate's commit step |
| `fix-checker` *(agent)* | After a fix round, answers resolved / not-resolved / introduced-new for one finding |

The orchestrator's runtime — checkpoint, envelope, resume, route, sync —
lives in `task-orchestrator/scripts/` (bash + jq + git + gh on the host)
with its own tests under `scripts/tests/`.

**Verification**

| | |
|---|---|
| `verify-backend-output` | Prove API behaviour with executed requests and multi-step flows, not code reading |
| `verify-frontend-output` | Prove user-visible behaviour in a real browser, at an honest proof level |
| `promote-e2e` | Turn a passing verification's throwaway specs into committed e2e coverage |

**Pull requests**

| | |
|---|---|
| `create-pr` | Open the branch's PR: body from the template, preview media uploaded with `gh --attach` |
| `get-pr-comments` | Review threads → grouped, actionable summary |
| `resolve-pr-comment` | Reply on a thread, then resolve it |
| `maintain-pr-description` | Rewrite the body so it describes HEAD, not the first submit |
| `monitor-ci-and-reviews` | Watch checks and incoming review until they settle, then triage |
| `pr-preview-media` | Verification recordings → MP4s and stills uploaded into the PR body with `gh --attach` |

**Writing and thinking**

| | |
|---|---|
| `restate` | Compress a noisy ask into a five-line frame before scoping |
| `investigate` | Grounded how/why of a subsystem from sources of truth, ADRs and code |
| `coding-guidelines` | Simplicity-first, surgical-change rules the executors condense |
| `tdd` | Red-green vertical slices (vendored from Matt Pocock) |
| `technical-writing` | Diátaxis / developer-style gate for docs, PR bodies, skill markdown |
| `unslop` | Strip AI tells from diffs, docs, PR prose |
| `show-me` | Pick a visual shape (table, tree, diff, mermaid) for a PR body or reply |
| `gh-stack` | Stacked branches and PRs with the gh-stack extension |

**Environment**

| | |
|---|---|
| `devcontainer` | Per-worktree container workflow, with a working reference runtime in this repo |

## Install

**Claude Code** — as a plugin:

```bash
/plugin marketplace add vitoladev/skills
/plugin install vitola-skills@vitola
```

Or vendor it into a single project: `git subtree add --prefix .agents/vendor/vitola-skills https://github.com/vitoladev/skills <tag> --squash`, then symlink the rendered `.claude/skills/*` and `.claude/agents/*` into the repo's own `.claude/`.

**Any agent** — via the [`skills`](https://github.com/vercel-labs/skills)
CLI, which needs no registry entry and discovers `.agents/skills/` directly:

```bash
npx skills add vitoladev/skills            # pick interactively
npx skills add vitoladev/skills --all      # all 20 skills, all detected agents
npx skills add vitoladev/skills --list     # just look
```

It symlinks into each detected agent's directory (`--copy` to copy instead)
and supports 75+ agents. Note it installs **skills only** — the agents
in `.agents/agents/` do not come along, so `task-orchestrator` will have
nothing to dispatch this way. Use the plugin, the subtree, or copy
`.claude/agents/` in by hand, if you want the orchestration set.

**Codex** — clone or copy `.agents/skills/` into the repo (or
`~/.agents/skills/` for personal scope). Codex reads that path natively; no
manifest needed.

**Cursor** — the plugin route renders `.cursor/agents/` too; otherwise copy
`.claude/agents/*.md` into the repo's `.claude/agents/` (Cursor searches
`.cursor/agents`, `.claude/agents` and `.codex/agents`). Cursor ignores the
`tools:` frontmatter field, so an agent's prose boundaries are what
constrain it there.

## Bindings

Nothing here names a tracker, a standards doc, a command wrapper or a review
bot. The orchestrator reads them from `routing.json` (the defaults, inside
the `task-orchestrator` skill) with the consuming repo's
`.agents/orchestrator.json` merged over it — objects merge, arrays and
scalars replace. A required binding still `null` after the merge stops the
run with its name; it is never guessed.

```jsonc
// .agents/orchestrator.json in the consuming repo
{
  "bindings": {
    "tracker":       { "kind": "linear", "team": "VIT", "id_pattern": "^VIT-\\d+$" },
    "standards_doc": "docs/CODING_STANDARDS.md",
    "command":       { "wrapper": "scripts/devcontainer/exec.sh" },
    "review_bot":    "pullfrog"          // a preset name, an object, or null for CI-only
  }
}
```

`review_bot` presets — `pullfrog`, `bugbot`, `codex`, `claude` — share one
shape: `trigger` (comment to post, or null when the bot reviews on its own),
`author` (the login its reviews and threads carry), `check` (the reviewer
ran) and `verdict` (must pass on HEAD; null means "latest review by `author`
is on HEAD with no unresolved thread"). Pass `{ "preset": "codex", "verdict":
"codex-approved" }` to start from a preset and override. Only `pullfrog` is
verified against a live PR today; the other logins are marked `unverified`
in `routing.json` until someone confirms them.

A concern the repo does not scope is dropped by setting its label to
`null` (`"labels": { "contract": null }`).

`task-orchestrator/scripts/bindings.sh` prints the merged result;
`bindings.sh --check` names what is still unresolved.

## Layout

```
.agents/skills/         canonical skills, harness-neutral — Codex and `npx skills` read here
.agents/agents/         canonical agents, harness-neutral
.agents/agent-manifest.json   per-harness agent frontmatter (tools, fallback model)
.claude/skill-models.json     per-skill Claude Code frontmatter (model, fork)
.claude/skills/         rendered from the canon — Claude Code and the plugin read here
.claude/agents/         rendered from the canon — Claude Code, Cursor and Codex read here
.cursor/agents/         rendered from the canon — Cursor
.claude-plugin/         plugin + marketplace manifests
.githooks/              pre-commit: rendered copies match the canon, runtime tests pass
scripts/skills/, scripts/agents/   the two render scripts (`--check` for CI)
.devcontainer/, scripts/devcontainer/   reference devcontainer runtime, keyed per worktree
```

The rendered directories are committed real files, not symlinks: a plugin
install copies the tree and does not promise to keep links. Edit the canon
and the manifests, run `scripts/skills/sync-claude-skills.sh` and
`scripts/agents/sync-agents.sh`, commit both. `git config core.hooksPath
.githooks` once per clone makes pre-commit refuse a stale copy.

Skills and agents diverge because the ecosystems did. Skills standardised on
a neutral `.agents/skills/`; subagents never did — Cursor and Codex instead
read each other's tool-specific directories, so `.claude/agents/` is the one
path all three honour.
