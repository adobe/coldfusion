#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../../.."
# NOTE: Ollama / mistral:latest check intentionally skipped — assumed running.
# If you want to add it back, re-insert:
#   ollama list | grep -q "mistral:latest" || { echo "FAIL: mistral:latest not pulled"; exit 1; }

echo "==> State dir writable"
test -w StyleMart/api/agent/s2/state/preferences/ || { echo "FAIL: state dir not writable"; exit 1; }
echo "OK: state/preferences/ is writable"

echo "==> Ref endpoint reachable"
curl -fsSL -o /dev/null "http://localhost:8500/api/agent/s2/ref/chat/sessions" -X POST -H "Accept: application/json" -H "Content-Type: application/json"
echo "OK: ref openSession returned 200"

echo "==> Lab endpoint reachable"
curl -fsSL -o /dev/null "http://localhost:8500/api/agent/s2/lab/chat/sessions" -X POST -H "Accept: application/json" -H "Content-Type: application/json"
echo "OK: lab openSession returned 200"

echo "==> Cross-isolation grep"
LAB_REFS=$(grep -rn 'api\.agent\.s2\.lab' StyleMart/api/agent/s2/ref/ 2>/dev/null || true)
[[ -z "$LAB_REFS" ]] || { echo "FAIL: ref/ contains lab.* references:"; echo "$LAB_REFS"; exit 1; }
REF_REFS=$(grep -rn 'api\.agent\.s2\.ref' StyleMart/api/agent/s2/lab/ 2>/dev/null || true)
[[ -z "$REF_REFS" ]] || { echo "FAIL: lab/ contains ref.* references:"; echo "$REF_REFS"; exit 1; }
echo "OK: lab/ref isolation clean"

echo
echo "All pre-flight checks passed."
