# [Contract] <schema or path change>

> Sub-issue of `VIT-<n>`. Label: `contract`.

## Requirements

<!-- Numbered and checkable. Name the exact schemas/paths added or changed in openapi.yaml, and every field's type, required-ness, and CONTEXT.md entity it represents. -->

1. <requirement>
2. <requirement>

## Implementation plan

<!-- The decisions, not a tutorial: which schemas/paths in packages/api-contract/openapi.yaml change, and why this shape (not an alternative) matches the parent's Scope. Every non-obvious decision here was pressure-tested with the requester, not assumed. -->

- `packages/api-contract/openapi.yaml` — <schemas/paths touched>.
- Regen: `scripts/devcontainer/exec.sh pnpm generate` regenerates `apps/api/internal/httpapi/gen.go` and `packages/api-contract/src/schema.d.ts` — never hand-edit either.
- Verify: regen produces the expected generated-file diff and nothing else (no unrelated schema drift).
