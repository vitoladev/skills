# [Infra] <resource change>

> Sub-issue of `VIT-<n>`. Label: `infra`.

## Requirements

<!-- Numbered and checkable. Name the exact DynamoDB table/index, Lambda config, or API Gateway route changed, and the access pattern it exists to serve. -->

1. <requirement>
2. <requirement>

## Implementation plan

<!-- The decisions, not a tutorial: the packages/infra/lib/infra-stack.ts resource(s) touched, and why this shape matches the access pattern the backend slice needs. Every non-obvious decision here was pressure-tested with the requester, not assumed. -->

- `packages/infra/lib/infra-stack.ts` — <resource(s) touched>.
- Verify: `scripts/devcontainer/exec.sh pnpm --filter infra lint` (`tsc --noEmit`) and `pnpm --filter infra test` pass; note any change that also needs a `cdk synth`/deploy check to prove.
