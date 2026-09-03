---
name: task-orchestrator
description: |
  Drive a parent issue to a published stack of PRs, one per sub-issue, each
  verified and reviewed. Invoke as /task-orchestrator <issue id>.
disable-model-invocation: true
---

# Task orchestrator

Entry point only. The full process — issue resolution, stack setup, packet
assembly, per-slice dispatch and gating, publish, report — lives on the
`orchestration-coordinator` agent, not here.

When invoked as `/task-orchestrator <issue identifier or URL>`: dispatch one
foreground `orchestration-coordinator` agent, its prompt carrying that
argument verbatim. Relay its final report back to the user unedited — do not
execute any of the process yourself, and do not summarize or trim the
coordinator's report.

Requires these agents in `.claude/agents/` (project) or `~/.claude/agents/`
(user): `orchestration-coordinator`, `backend-executor`,
`frontend-executor`, and `committer`. That location is read by Claude Code,
Cursor, and Codex alike — there is no tool-neutral agents directory the way
there is for skills.
