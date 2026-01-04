# Tic-Tac-Toe Helm Charts

This directory contains Helm charts for deploying the Tic-Tac-Toe microservices application to Kubernetes.

## Charts Overview

- **global-config**: Global ConfigMap for all services
- **game-logic-service**: Game Logic Service
- **gateway-service**: Gateway Service (WebSocket)
- **archive-service**: Archive Service
- **statistics-service**: Statistics Service (REST API)
- **frontend**: Frontend Application

## Prerequisites

- Kubernetes cluster
- Helm 3.x
- Ingress controller (nginx recommended)
- Kafka and MongoDB running in the cluster

## Installation Order

1. **Install global-config first** (creates ConfigMap for all services):
   ```bash
   helm install global-config ./global-config
   ```

2. **Install backend services**:
   ```bash
   helm install game-logic-service ./game-logic-service
   helm install gateway-service ./gateway-service
   helm install archive-service ./archive-service
   helm install statistics-service ./statistics-service
   ```

3. **Install frontend**:
   ```bash
   helm install frontend ./frontend
   ```

## Configuration

### Global Config

Edit `global-config/values.yaml` to configure:
- Kafka connection settings
- MongoDB connection settings
- Service-specific configurations
- Ingress hostnames

### Service-Specific Configuration

Each service has its own `values.yaml` where you can configure:
- Image repository and tag
- Replica count
- Resource limits/requests
- Ingress settings (where applicable)

## Ingress Configuration

The following services expose Ingress:
- **Frontend**: `tic-tac-toe.local`
- **Gateway**: `gateway.tic-tac-toe.local` (WebSocket)
- **Statistics API**: `api.tic-tac-toe.local`

Update `/etc/hosts` or configure DNS:
```
<INGRESS_IP> tic-tac-toe.local
<INGRESS_IP> gateway.tic-tac-toe.local
<INGRESS_IP> api.tic-tac-toe.local
```

## Environment Variables

All services mount environment variables from the `global-config-config` ConfigMap. The ConfigMap contains:

- `KAFKA_BOOTSTRAP_SERVERS`
- `KAFKA_MOVES_TOPIC`
- `KAFKA_STATE_TOPIC`
- `MONGO_URL`
- `MONGO_DB_NAME`
- `GATEWAY_WS_URL` (for frontend)
- Service-specific variables

## WebSocket Configuration

The frontend uses a runtime-injected WebSocket URL. The URL is:
1. Defined in `global-config/values.yaml` as `services.gateway.wsUrl`
2. Injected at pod startup via an init container
3. Loaded by the frontend HTML as `/config/gateway-ws-url.js`

## Upgrading

To upgrade a service:
```bash
helm upgrade <service-name> ./<service-chart>
```

To upgrade all services:
```bash
helm upgrade global-config ./global-config
helm upgrade game-logic-service ./game-logic-service
helm upgrade gateway-service ./gateway-service
helm upgrade archive-service ./archive-service
helm upgrade statistics-service ./statistics-service
helm upgrade frontend ./frontend
```

## Uninstalling

To uninstall all services:
```bash
helm uninstall frontend
helm uninstall statistics-service
helm uninstall archive-service
helm uninstall gateway-service
helm uninstall game-logic-service
helm uninstall global-config
```

## Troubleshooting

### Check ConfigMap
```bash
kubectl get configmap global-config-config -o yaml
```

### Check Pod Logs
```bash
kubectl logs -l app.kubernetes.io/name=game-logic-service
kubectl logs -l app.kubernetes.io/name=gateway-service
kubectl logs -l app.kubernetes.io/name=frontend
```

### Check Ingress
```bash
kubectl get ingress
kubectl describe ingress <ingress-name>
```

### Verify Environment Variables
```bash
kubectl exec -it <pod-name> -- env | grep KAFKA
kubectl exec -it <pod-name> -- env | grep MONGO
```

