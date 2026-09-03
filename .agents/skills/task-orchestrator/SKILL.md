---
name: task-orchestrator
description: |
  Drive a parent issue end to end — dispatch each sub-issue to its executor
  agent (backend-executor / frontend-executor), verify and code-review every
  slice, and publish a gh-stack of PRs, one per sub-issue. Invoke as
  /task-orchestrator <issue identifier or URL>.
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
