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
  exit 100
fi

echo "[OK] Context verified: ${CURRENT_CTX}"

echo "[INFO] Scaling ArgoCD Deployments to 1"
$KUBECTL scale deploy -n "$ARGO_NS" --all --replicas=1

echo "[INFO] Scaling ArgoCD StatefulSets to 1"
$KUBECTL scale sts -n "$ARGO_NS" --all --replicas=1

echo "[INFO] Waiting for ArgoCD pods to become Ready"
$KUBECTL wait \
  --namespace "$ARGO_NS" \
  --for=condition=Ready pod \
  -l app.kubernetes.io/part-of=argocd \
  --timeout=10m

echo "[INFO] Re-enabling auto-sync for all ArgoCD Applications"
$KUBECTL get applications.argoproj.io -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  echo "  → Patching $ns/$name"
  $KUBECTL patch applications.argoproj.io "$name" \
    -n "$ns" \
    --type merge \
    -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":true,"prune":true}}}}'
done

echo "[SUCCESS] Start job completed safely on context '${CURRENT_CTX}'"
