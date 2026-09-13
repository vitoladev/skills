---
type: llm
weight: 2
---

The answer classifies the layer as code (not docs-only, because `.go`
files changed), posts the binding's trigger comment once (`@codex review`),
then runs `/monitor-ci-and-reviews`. Merge-ready is stated as: required
checks green on the current head AND, since `verdict` is null, the latest
review by `chatgpt-codex-connector[bot]` is on the current head with no
unresolved thread it opened. It must not mention `@pullfrog`, must not
invent a `codex-approval` check, and must not skip the trigger because a
README changed.
