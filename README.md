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
| `task-orchestrator` | Entry point that dispatches the coordinator |
| `orchestration-coordinator` *(agent)* | Drives one parent issue to a published stack, gating every slice through verify → commit → review |
| `backend-executor` / `frontend-executor` *(agents)* | Implement one slice each, carrying the code quality rules inline |
| `committer` *(agent)* | Owns the gate's commit step |

**Verification**

| | |
|---|---|
| `verify-backend-output` | Prove API behaviour with executed requests and multi-step flows, not code reading |
| `verify-frontend-output` | Prove user-visible behaviour in a real browser, at an honest proof level |
| `promote-e2e` | Turn a passing verification's throwaway specs into committed e2e coverage |

**Pull requests**

| | |
|---|---|
| `get-pr-comments` | Review threads → grouped, actionable summary |
| `resolve-pr-comment` | Reply on a thread, then resolve it |
| `maintain-pr-description` | Rewrite the body so it describes HEAD, not the first submit |
| `monitor-ci-and-reviews` | Watch checks and incoming review until they settle, then triage |
| `pr-preview-media` | CI browser recordings → GIFs and stills embedded in the PR body |

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

Or vendor it into a single project by copying `.agents/skills/` and `agents/`.

**Any agent** — via the [`skills`](https://github.com/vercel-labs/skills)
CLI, which needs no registry entry and discovers `.agents/skills/` directly:

```bash
npx skills add vitoladev/skills            # pick interactively
npx skills add vitoladev/skills --all      # all 11 skills, all detected agents
npx skills add vitoladev/skills --list     # just look
```

It symlinks into each detected agent's directory (`--copy` to copy instead)
and supports 75+ agents. Note it installs **skills only** — the four agents
in `agents/` do not come along, so `task-orchestrator` will not find its
coordinator this way. Use the plugin, or copy `agents/` in by hand, if you
want the orchestration set.

**Codex** — clone or copy `.agents/skills/` into the repo (or
`~/.agents/skills/` for personal scope). Codex reads that path natively; no
manifest needed.

**Cursor** — copy `agents/*.md` into `.claude/agents/` (Cursor searches
`.cursor/agents`, `.claude/agents` and `.codex/agents`). Note that Cursor
ignores the `tools:` frontmatter field, so an agent's prose boundaries are
what constrain it there.

## Layout

```
.agents/skills/     canonical skills — the cross-tool convention Codex reads
.claude/skills/     symlinks into the above (Claude Code reads only here)
agents/             canonical agents — also the Claude plugin default location
.claude/agents/     symlinks into the above (Claude Code, Cursor and Codex read here)
.claude-plugin/     plugin + marketplace manifests
.devcontainer/      reference devcontainer runtime
scripts/devcontainer/   up.sh, exec.sh, down.sh — keyed per git worktree
```

Skills and agents diverge because the ecosystems did. Skills standardised on
a neutral `.agents/skills/`; subagents never did — Cursor and Codex instead
read each other's tool-specific directories, so `.claude/agents/` is the one
path all three honour.
