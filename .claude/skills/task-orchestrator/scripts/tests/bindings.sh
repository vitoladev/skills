#!/usr/bin/env bash
# Exercises bindings.sh against throwaway overlays. Host tools only.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
B="$HERE/../bindings.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fail=0
ok()   { echo "ok   $1"; }
bad()  { echo "FAIL $1" >&2; fail=1; }
expect() { # name expected actual
  [ "$2" = "$3" ] && ok "$1" || { bad "$1: expected $2, got $3"; }; }

# no overlay: every required binding is reported, exit 1
if out="$(ORCH_ROOT="$T" "$B" --check 2>&1)"; then bad "no overlay should fail"; else
  for k in tracker.kind tracker.id_pattern standards_doc command.wrapper; do
    grep -q "unresolved required binding: $k" <<<"$out" && ok "reports $k" || bad "missing report for $k"; done; fi

# preset by name expands, defaults survive under the merge
cat > "$T/a.json" <<'EOF'
{"bindings":{"tracker":{"kind":"linear","team":"VIT","id_pattern":"^VIT-\\d+$"},"standards_doc":"docs/CODING_STANDARDS.md","command":{"wrapper":"scripts/devcontainer/exec.sh"},"review_bot":"pullfrog"}}
EOF
ORCH_OVERLAY="$T/a.json" "$B" --check >/dev/null && ok "preset overlay resolves" || bad "preset overlay should resolve"
expect "preset expands author" pullfrog "$(ORCH_OVERLAY="$T/a.json" "$B" review_bot.author | jq -r .)"
expect "preset expands verdict" pullfrog-approval "$(ORCH_OVERLAY="$T/a.json" "$B" review_bot.verdict | jq -r .)"
expect "default host_only kept" '["git","gh"]' "$(ORCH_OVERLAY="$T/a.json" "$B" command.host_only)"
expect "default state_dir kept" docs/ai/executions "$(ORCH_OVERLAY="$T/a.json" "$B" state_dir | jq -r .)"

# preset object with overrides; arrays replace; nested objects merge
cat > "$T/b.json" <<'EOF'
{"bindings":{"tracker":{"kind":"github","id_pattern":"^#\\d+$"},"standards_doc":"CONTRIBUTING.md","command":{"wrapper":"direct","host_only":["git"]},"review_bot":{"preset":"codex","verdict":"codex-approved"},"labels":{"contract":"backend"}}}
EOF
expect "preset override wins" codex-approved "$(ORCH_OVERLAY="$T/b.json" "$B" review_bot.verdict | jq -r .)"
expect "preset base kept" 'chatgpt-codex-connector[bot]' "$(ORCH_OVERLAY="$T/b.json" "$B" review_bot.author | jq -r .)"
expect "preset key dropped" null "$(ORCH_OVERLAY="$T/b.json" "$B" review_bot.preset)"
expect "array replaces" '["git"]' "$(ORCH_OVERLAY="$T/b.json" "$B" command.host_only)"
expect "object merges" '{"backend":"backend","frontend":"frontend","contract":"backend","infra":"infra"}' "$(ORCH_OVERLAY="$T/b.json" "$B" labels)"

# a null label drops the concern; the others keep their defaults
echo '{"bindings":{"tracker":{"kind":"x","id_pattern":"y"},"standards_doc":"z","command":{"wrapper":"w"},"labels":{"contract":null}}}' > "$T/l.json"
expect "null label dropped" '{"backend":"backend","frontend":"frontend","infra":"infra"}' "$(ORCH_OVERLAY="$T/l.json" "$B" labels)"

# review_bot null is CI-only, not unresolved
echo '{"bindings":{"tracker":{"kind":"x","id_pattern":"y"},"standards_doc":"z","command":{"wrapper":"w"},"review_bot":null}}' > "$T/c.json"
ORCH_OVERLAY="$T/c.json" "$B" --check >/dev/null && ok "null review_bot resolves" || bad "null review_bot should resolve"
expect "null review_bot stays null" null "$(ORCH_OVERLAY="$T/c.json" "$B" review_bot)"

# unknown preset is an error
echo '{"bindings":{"review_bot":"nope"}}' > "$T/d.json"
if ORCH_OVERLAY="$T/d.json" "$B" >/dev/null 2>"$T/err"; then bad "unknown preset should fail"; else
  grep -q "unknown review_bot preset nope" "$T/err" && ok "unknown preset named" || bad "unknown preset message"; fi

# invalid overlay JSON is an error, not silently ignored
echo '{nope' > "$T/e.json"
ORCH_OVERLAY="$T/e.json" "$B" >/dev/null 2>&1 && bad "invalid overlay should fail" || ok "invalid overlay fails"

# routing keys outside bindings pass through untouched and $comment is gone
expect "phases pass through" committer "$(ORCH_OVERLAY="$T/a.json" "$B" | jq -r .phases.commit.agent)"
expect "top-level comment stripped" false "$(ORCH_OVERLAY="$T/a.json" "$B" | jq 'has("$comment")')"

[ "$fail" -eq 0 ] && echo "bindings: all passed" || { echo "bindings: failures" >&2; exit 1; }
