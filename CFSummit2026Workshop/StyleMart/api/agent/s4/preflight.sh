#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../../.."
# NOTE: Ollama / mistral:latest check intentionally skipped — assumed running.
# If you want to add it back, re-insert:
#   ollama list | grep -q "mistral:latest" || { echo "FAIL: mistral:latest not pulled"; exit 1; }

echo "==> State dir writable"
test -w StyleMart/api/agent/s4/state/preferences/ || { echo "FAIL: state dir not writable"; exit 1; }
echo "OK: state/preferences/ is writable"

echo "==> Ref endpoint reachable"
curl -fsSL -o /dev/null "http://localhost:8500/api/agent/s4/ref/chat/sessions" -X POST -H "Accept: application/json" -H "Content-Type: application/json"
echo "OK: ref openSession returned 200"

echo "==> Lab endpoint reachable"
curl -fsSL -o /dev/null "http://localhost:8500/api/agent/s4/lab/chat/sessions" -X POST -H "Accept: application/json" -H "Content-Type: application/json"
echo "OK: lab openSession returned 200"

echo "==> Cross-isolation grep"
LAB_REFS=$(grep -rn 'api\.agent\.s4\.lab' StyleMart/api/agent/s4/ref/ 2>/dev/null || true)
[[ -z "$LAB_REFS" ]] || { echo "FAIL: ref/ contains lab.* references:"; echo "$LAB_REFS"; exit 1; }
REF_REFS=$(grep -rn 'api\.agent\.s4\.ref' StyleMart/api/agent/s4/lab/ 2>/dev/null || true)
[[ -z "$REF_REFS" ]] || { echo "FAIL: lab/ contains ref.* references:"; echo "$REF_REFS"; exit 1; }
# Per-side configs: ai.ref.properties must NOT name lab.tools, ai.lab.properties must NOT name ref.tools.
REF_CFG_BAD=$(grep -n 'api\.agent\.s4\.lab' StyleMart/api/agent/s4/config/ai.ref.properties 2>/dev/null || true)
[[ -z "$REF_CFG_BAD" ]] || { echo "FAIL: ai.ref.properties contains lab.* refs:"; echo "$REF_CFG_BAD"; exit 1; }
LAB_CFG_BAD=$(grep -n 'api\.agent\.s4\.ref' StyleMart/api/agent/s4/config/ai.lab.properties 2>/dev/null || true)
[[ -z "$LAB_CFG_BAD" ]] || { echo "FAIL: ai.lab.properties contains ref.* refs:"; echo "$LAB_CFG_BAD"; exit 1; }
echo "OK: lab/ref isolation clean"

echo
echo "All pre-flight checks passed."
