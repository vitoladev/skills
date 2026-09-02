---
name: ticket-scoping
description: |
  Turn a PRD/spec into a Linear parent issue plus backend/frontend/
  contract/infra sub-issues shaped for task-orchestrator's executors to
  consume — numbered Requirements, a pressure-tested Implementation plan,
  and a Verify command per sub-issue. Invoke as /ticket-scoping <spec text,
  a docs/product file section, or an existing VIT-<n> to scope>.
disable-model-invocation: true
---

# Ticket scoping

Turn a PRD/spec into one Linear parent issue and its backend/frontend/
contract/infra sub-issues, each shaped so `orchestration-coordinator`,
`backend-executor`, and `frontend-executor` can consume it without
guessing: the parent carries the PRD and acceptance criteria those agents
read as ground truth; each sub-issue's **Requirements** section is the
executor's done-bar, its **Implementation plan** the seams, its **Verify**
line the final check. This runs inline, in conversation with the
requester — it leans on `AskUserQuestion` throughout, which the agents it
feeds cannot do themselves.

The five templates below are the section shapes the rest of this run fills
in: `references/parent.md`, `references/sub-issue-backend.md`,
`references/sub-issue-frontend.md`, `references/sub-issue-contract.md`,
`references/sub-issue-infra.md`. Read the ones you need when you reach
steps 2 and 3, not before.

## 1. Resolve the spec and target parent

The argument is spec text, a `docs/product/<file>.md` path (optionally a
section within it, e.g. "6.2 Check-in"), or an existing `VIT-<n>` to
re-scope. Read `CONTEXT.md` in full — every domain term the parent and its
sub-issues use must trace to that glossary; a term the feature needs that
isn't there is a stop-and-ask, never an invented synonym ("Do not drift to
synonyms" is the glossary's own rule, not just this skill's).

Determine the target: a bare `VIT-<n>` given (or one the spec names, e.g.
`docs/product/foundations-prd.md`'s scope table) means update that parent
in place via the Linear MCP; otherwise this run creates a fresh one.

Complete when the spec's scope is pinned to a source (pasted text or a
named file/section), every glossary term it needs is confirmed present in
`CONTEXT.md`, and the target parent (new, or an existing `VIT-<n>`) is
known.

## 2. Draft the parent

Fill `references/parent.md`'s shape from the spec. Ask — via
`AskUserQuestion`, presenting the reading you would otherwise pick
silently as one option among the real alternatives — whenever the spec
leaves genuinely open: a Scope boundary, a Non-goal, an Acceptance
criterion's exact observable outcome, or which sub-issue labels this
feature needs (`backend` and `frontend` are close to universal; `contract`
only when the API shape changes beyond what an existing sub-issue already
covers; `infra` only when DynamoDB/Lambda/API Gateway shape changes).

Complete when every "High-level PRD" subsection holds checkable content —
each Acceptance criterion is one observable outcome a verifier could mark
Passed/Failed from evidence alone — and the sub-issue label set for step 3
is decided, not assumed.

## 3. Pressure-test each sub-issue's implementation plan

For each label decided in step 2, draft a first-pass Implementation plan
from the parent plus that label's `references/sub-issue-<label>.md` shape
— the seams, files, and what the test/Verify line must prove. Then
pressure-test it: for every decision in the plan that would send the
executor down a materially different path if guessed wrong (a store-seam
choice, a schema shape, a component boundary, which side owns a
computation), ask via `AskUserQuestion` rather than pick. Skip the
question only when any reasonable reading of the parent converges on the
same answer — pressure-testing every line turns this into an
interrogation, not a review.

Hard gate: a sub-issue does not reach step 4 until its Implementation plan
has been pressure-tested this way. An unquestioned plan on a
non-obvious decision is not done, no matter how plausible it reads.

## 4. Create the issues

Parent first — create it via the Linear MCP's issue-creation tool (or
update the existing `VIT-<n>` via its issue-update tool, per step 1's
resolution), filled from step 2. Then each sub-issue: issue-creation tool,
`parentId` set to the parent, the label from step 2 applied, body filled
from its `references/sub-issue-<label>.md` shape and step 3's
pressure-tested plan.

Complete when the parent and every planned sub-issue exist in Linear with
their labels, each sub-issue's Requirements are numbered, and its Verify
line names a concrete command (backend/contract/infra) or browser flow
(frontend) — never a placeholder.

## 5. Report

The parent's `VIT-<n>` and title. Then each sub-issue: `VIT-<n>`, label,
one-line surface. Note the stack order for reference — contract, then
backend (with any infra), then frontend — matching how
`orchestration-coordinator` will build it. Close with the follow-up
command: `/task-orchestrator VIT-<n>` (the parent's identifier).
