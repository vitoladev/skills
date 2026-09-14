# vitola-skills

Project-agnostic skills and agents that take a feature from a spec to a
merged stack of pull requests. They scope the tickets, drive each slice
through implement, verify, review, and publish, and keep each PR body
true to its branch afterwards.

Nothing here names a repo. The consuming repo supplies its tracker,
standards doc, command wrapper, and review bot in one file,
`.agents/orchestrator.json` (see [Bindings](#bindings)). A binding the
repo leaves unset stops the run with its name. No skill guesses one.

## What's inside

**Orchestration**

| | |
|---|---|
| `ticket-scoping` | Turns a PRD or spec into a parent issue and its backend, frontend, contract, and infra sub-issues, each with numbered requirements and a pressure-tested plan |
| `task-orchestrator` | Drives one parent issue to a published stack in the calling session. Every slice passes verify, commit, and review before the next starts. Every phase writes a checkpoint, so `/task-orchestrator resume <id>` continues a killed run where it stopped |
| `backend-executor`, `frontend-executor` *(agents)* | Implement one slice each. They carry the coding rules inline and never delegate |
| `backend-verifier`, `frontend-verifier` *(agents)* | Prove one slice's acceptance criteria with executed requests or a real browser. They never fix |
| `code-reviewer` *(agent)* | Reviews one slice's diff on the Standards and Spec axes in one context, and reports P0 to P3 findings with a verdict |
| `committer` *(agent)* | Makes the commit at the gate's commit step |
| `fix-checker` *(agent)* | After a fix round, answers `resolved`, `not-resolved`, or `introduced-new` for one finding |

The orchestrator's runtime (checkpoint, envelope, resume, route, sync)
lives in `task-orchestrator/scripts/`. It needs bash, jq, git, and gh on
the host, and its tests are under `scripts/tests/`.

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
| `get-pr-comments` | Summarises the review threads on a PR, grouped by what deserves a fix |
| `resolve-pr-comment` | Reply on a thread, then resolve it |
| `maintain-pr-description` | Rewrite the body so it describes HEAD, not the first submit |
| `monitor-ci-and-reviews` | Watch checks and incoming review until they settle, then triage |
| `pr-preview-media` | Turns verification recordings into MP4s and stills and uploads them into the PR body with `gh --attach` |

**Writing and thinking**

| | |
|---|---|
| `restate` | Compress a noisy ask into a five-line frame before scoping |
| `investigate` | How and why a subsystem works, cited from sources of truth, ADRs, and code |
| `coding-guidelines` | Simplicity-first, surgical-change rules the executors condense |
| `tdd` | Red-green vertical slices with test-shape and mocking rules |
| `technical-writing` | Diátaxis and developer-style gate for docs, PR bodies, and skill markdown |
| `unslop` | Strip AI tells from diffs, docs, and PR prose |
| `show-me` | Pick a visual shape (table, tree, diff, mermaid) for a PR body or reply |
| `gh-stack` | Stacked branches and PRs with the gh-stack extension |

**Environment**

| | |
|---|---|
| `devcontainer` | Per-worktree container workflow, with a working reference runtime in this repo |

## Install

### Claude Code

Install it as a plugin:

```bash
/plugin marketplace add vitoladev/skills
/plugin install vitola-skills@vitola
```

Or vendor it into one project as a git subtree, then symlink the rendered
`.claude/skills/*` and `.claude/agents/*` into the repo's own `.claude/`:

```bash
git subtree add --prefix .agents/vendor/vitola-skills https://github.com/vitoladev/skills <tag> --squash
```

### Any agent

The [`skills`](https://github.com/vercel-labs/skills) CLI needs no
registry entry and reads `.agents/skills/` directly:

```bash
npx skills add vitoladev/skills            # pick interactively
npx skills add vitoladev/skills --all      # all 20 skills, all detected agents
npx skills add vitoladev/skills --list     # list without installing
```

It symlinks into each detected agent's directory (`--copy` copies instead)
and supports more than 75 agents. It installs skills only. The agents in
`.agents/agents/` do not come along, so `task-orchestrator` has nothing to
dispatch this way. For the orchestration set, use the plugin, the subtree,
or copy `.claude/agents/` in by hand.

### Codex

Clone or copy `.agents/skills/` into the repo, or into `~/.agents/skills/`
for personal scope. Codex reads that path natively and needs no manifest.

### Cursor

The rendered `.cursor/agents/` ships with the plugin and the subtree.
Otherwise copy `.claude/agents/*.md` into the repo's `.claude/agents/`;
Cursor searches `.cursor/agents`, `.claude/agents`, and `.codex/agents`.
Cursor ignores the `tools:` frontmatter field, so only an agent's prose
constrains it there.

## Bindings

Nothing here names a tracker, a standards doc, a command wrapper, or a
review bot. The orchestrator reads them from `routing.json` (the defaults,
inside the `task-orchestrator` skill) with the consuming repo's
`.agents/orchestrator.json` merged over it. Objects merge key by key.
Arrays and scalars in the overlay replace the default. A required binding
that is still `null` after the merge stops the run with its name. The
orchestrator never guesses one.

```jsonc
// .agents/orchestrator.json in the consuming repo
{
  "bindings": {
    "tracker":       { "kind": "linear", "team": "ABC", "id_pattern": "^ABC-\\d+$" },
    "standards_doc": "docs/CODING_STANDARDS.md",
    "command":       { "wrapper": "scripts/devcontainer/exec.sh" },
    "review_bot": {                                   // or null: CI is the only gate
      "trigger": "gh pr comment $PR --body '@reviewer review'",  // null: the bot reviews on its own
      "author":  "reviewer[bot]",                     // login its reviews and threads carry
      "check":   "reviewer",                          // "the reviewer ran" check; optional
      "verdict": "reviewer-approval",                 // must pass on HEAD; null: see below
      "skip_on": ["docs-only"]
    }
  }
}
```

The repo describes its review bot; no skill names one. Whichever bot a
repo runs, the skills read this one shape. `author` is the only required
key. When `verdict` is null, a layer is review-clean when the latest
review by `author` is on HEAD and no thread that `author` opened is
unresolved. `skip_on` lists the layer classes the bot never reviews. A
layer is `docs-only` when every changed path ends in `.md`.

To drop a concern the repo does not scope, set its label to `null`
(`"labels": { "contract": null }`).

The gate has one setting, beside the bindings: `"gate": { "max_fix_rounds": 3 }`.
It is the number of fix, commit, and fix-check rounds a slice may spend
on P0 and P1 findings. Past that number the slice is blocked, and the run
stops without opening that slice's PR.

`task-orchestrator/scripts/bindings.sh` prints the merged result.
`bindings.sh --check` names what is still unresolved.

## Layout

```
.agents/skills/         canonical skills, harness-neutral; Codex and `npx skills` read here
.agents/agents/         canonical agents, harness-neutral
.agents/agent-manifest.json   per-harness agent frontmatter (tools, fallback model)
.claude/skill-models.json     per-skill Claude Code frontmatter (model, fork)
.claude/skills/         rendered from the canon; Claude Code and the plugin read here
.claude/agents/         rendered from the canon; Claude Code, Cursor, and Codex read here
.cursor/agents/         rendered from the canon; Cursor reads here
.claude-plugin/         plugin and marketplace manifests
.githooks/              pre-commit: rendered copies match the canon, runtime tests pass
scripts/skills/, scripts/agents/   the two render scripts (`--check` for CI)
.devcontainer/, scripts/devcontainer/   reference devcontainer runtime, keyed per worktree
```

The rendered directories are committed as real files, not symlinks,
because a plugin install copies the tree and does not promise to keep
links. To change a skill or agent, edit the canon and the manifests, run
`scripts/skills/sync-claude-skills.sh` and `scripts/agents/sync-agents.sh`,
and commit both. Run `git config core.hooksPath .githooks` once per clone
so pre-commit refuses a stale copy.

## Credits

Some skills started as copies of other people's work and have since
diverged. `technical-writing` and `unslop` adapt the same-named skills
from [pstack](https://github.com/vitoladev/pstack). `restate` follows
poteto's indirect-prompt pattern as pstack's guide describes it, and
`investigate` covers the ground of pstack's `/how` and `/why`. `tdd`
comes from [mattpocock/skills](https://github.com/mattpocock/skills)
(`skills/engineering/tdd`). `show-me` comes from
[humanlayer/skills](https://github.com/humanlayer/skills/blob/main/plugins/show-me/skills/show-me/SKILL.md).
None of them need the original plugin installed.

Skills and agents are laid out differently because the tools are. Skills
standardised on a neutral `.agents/skills/`. Subagents never did: Cursor
and Codex read each other's tool-specific directories, so
`.claude/agents/` is the one path all three honour.
