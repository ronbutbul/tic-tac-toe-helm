#!/usr/bin/env bash
set -euo pipefail

KUBECTL="kubectl"
REQUIRED_CTX="tic-automode"
ARGO_NS="argo-cd"

echo "[INFO] Switching kubectl context to '${REQUIRED_CTX}'"
$KUBECTL config use-context "${REQUIRED_CTX}" >/dev/null

CURRENT_CTX="$($KUBECTL config current-context 2>/dev/null || true)"

if [[ "$CURRENT_CTX" != "$REQUIRED_CTX" ]]; then
  echo "[FATAL] kubectl context mismatch!"
  echo "         Expected: ${REQUIRED_CTX}"
  echo "         Actual:   ${CURRENT_CTX:-<none>}"
  echo "[FATAL] Aborting. No changes were made."
  exit 100
fi

echo "[OK] Context verified: ${CURRENT_CTX}"

echo "[INFO] Disabling auto-sync for all ArgoCD Applications"
$KUBECTL get applications.argoproj.io -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  echo "  → Patching $ns/$name"
  $KUBECTL patch applications.argoproj.io "$name" \
    -n "$ns" \
    --type merge \
    -p '{"spec":{"syncPolicy":null}}'
done

echo "[INFO] Scaling ALL Deployments to 0"
$KUBECTL get deploy -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  echo "  → Scaling deploy $ns/$name"
  $KUBECTL scale deploy "$name" -n "$ns" --replicas=0
done

echo "[INFO] Scaling ALL StatefulSets to 0"
$KUBECTL get sts -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  echo "  → Scaling sts $ns/$name"
  $KUBECTL scale sts "$name" -n "$ns" --replicas=0
done

echo "[SUCCESS] Stop job completed safely on context '${CURRENT_CTX}'"
