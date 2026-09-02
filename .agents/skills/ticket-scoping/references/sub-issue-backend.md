# [Backend] <endpoint or behavior>

> Sub-issue of `VIT-<n>`. Label: `backend`.

## Requirements

<!-- Numbered and checkable — each is a line backend-executor's done-bar and the verify gate trace back to. Name the contract shapes (openapi.yaml), status codes, and the CONTEXT.md entities/fields involved explicitly (e.g. Visit.gateInAt, not "the timestamp"). -->

1. <requirement>
2. <requirement>

## Implementation plan

<!-- The decisions, not a tutorial: which files, which store seam (the memory.go / dynamo.go pair under the owning internal/<domain> package), what the test must prove. Every non-obvious decision here was pressure-tested with the requester, not assumed. -->

- `apps/api/...` — <what lands here and why this seam>.
- Test: <the behavior the test must prove, at the httptest handler boundary unless there's a reason not to>.
- Verify: `scripts/devcontainer/exec.sh bash -c 'curl -s localhost:8080/api/...'` → <expected output>.
