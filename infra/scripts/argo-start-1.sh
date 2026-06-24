#!/usr/bin/env bash
set -euo pipefail

ARGO_NS="argo-cd"

# Allow kubeconfig path from first argument or env variable
KUBECONFIG_PATH="${1:-${KUBECONFIG_PATH:-}}"

if [[ -z "$KUBECONFIG_PATH" ]]; then
  echo "[FATAL] Missing kubeconfig path."
  echo "Usage:"
  echo "  $0 /path/to/kubeconfig"
  echo ""
  echo "Or:"
  echo "  KUBECONFIG_PATH=/path/to/kubeconfig $0"
  exit 100
fi

if [[ ! -f "$KUBECONFIG_PATH" ]]; then
  echo "[FATAL] kubeconfig file does not exist:"
  echo "        $KUBECONFIG_PATH"
  exit 101
fi

KUBECTL=(kubectl --kubeconfig "$KUBECONFIG_PATH")

echo "[INFO] Using kubeconfig: ${KUBECONFIG_PATH}"

CURRENT_CTX="$("${KUBECTL[@]}" config current-context 2>/dev/null || true)"
echo "[INFO] kubeconfig current-context: ${CURRENT_CTX:-<none>}"

echo "[INFO] Verifying cluster access"
"${KUBECTL[@]}" cluster-info >/dev/null

echo "[OK] Cluster access verified"

echo "[INFO] Scaling ArgoCD Deployments to 1"
"${KUBECTL[@]}" scale deploy -n "$ARGO_NS" --all --replicas=1

echo "[INFO] Scaling ArgoCD StatefulSets to 1"
"${KUBECTL[@]}" scale sts -n "$ARGO_NS" --all --replicas=1

echo "[INFO] Waiting for ArgoCD pods to become Ready"
"${KUBECTL[@]}" wait \
  --namespace "$ARGO_NS" \
  --for=condition=Ready pod \
  -l app.kubernetes.io/part-of=argocd \
  --timeout=10m

echo "[INFO] Enabling auto-sync (prune=true, selfHeal=true) for all ArgoCD Applications"
"${KUBECTL[@]}" get applications.argoproj.io -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  [[ -z "${ns:-}" || -z "${name:-}" ]] && continue

  echo "  → Patching $ns/$name (enable auto-sync: prune+selfHeal)"
  "${KUBECTL[@]}" patch applications.argoproj.io "$name" \
    -n "$ns" \
    --type merge \
    -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
done

echo "[INFO] Scaling all Deployments with label app=kagent to 1 replica"
"${KUBECTL[@]}" get deploy -A -l app=kagent \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' |
while read -r ns name; do
  [[ -z "${ns:-}" || -z "${name:-}" ]] && continue

  echo "  → Scaling $ns/$name to 1"
  "${KUBECTL[@]}" scale deploy "$name" -n "$ns" --replicas=1
done

echo "[SUCCESS] Start job completed safely using kubeconfig '${KUBECONFIG_PATH}'"