# https-wrench Helm Chart

A production-ready Helm chart to deploy [https-wrench](https://github.com/xenOs76/https-wrench) (version >= 0.17.0) in continuous observability mode on Kubernetes.

The chart is packaged and published in **OCI format** to `ghcr.io/xenos76/charts/https-wrench`.

## Features

- **OCI Package Distribution:** Standard OCI registry publishing (`oci://ghcr.io/xenos76/charts/https-wrench`).
- **Continuous Observability:** Runs synthetic HTTPS requests at configurable intervals and exports Prometheus metrics on port `9090`.
- **Live Configuration Reload:** Updates probe targets without pod restarts using Kubernetes atomic ConfigMap projections (Inotify) or an HTTP `POST /-/reload` endpoint.
- **Prometheus ServiceMonitor:** Preconfigured CRD for automatic target discovery by Prometheus Operator.
- **Optional Gateway & Istio VirtualService:** Easily expose endpoints via Kubernetes Gateway API or Istio mesh routing.
- **Dual-Layer Schema Validation:** Chart values validated by `values.schema.json`, with probe configurations checked directly against upstream `https-wrench.schema.json`.
- **Hardened Defaults:** Non-root user (`65534`), dropped capabilities, read-only root filesystem, and configurable resource constraints.

## Working with OCI Chart Artifacts

### 1. Authenticate with GitHub Container Registry (if required)

Public charts can be pulled without authentication. For private packages or when publishing/authenticating:

```bash
echo "$GITHUB_TOKEN" | helm registry login ghcr.io --username <github-username> --password-stdin
```

### 2. Inspect OCI Chart & Default Values

To inspect metadata or default configuration directly from the OCI registry without downloading:

```bash
# View chart metadata
helm show chart oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0

# View default values.yaml
helm show values oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0

# View README from registry
helm show readme oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0
```

### 3. Install Chart from OCI Registry

**Basic installation (using chart default values):**

```bash
helm install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace
```

**Installation with custom values file:**

```bash
helm install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace \
  -f my-probes-values.yaml
```

**Installation passing multiple values files or inline overrides (`--set`):**

```bash
helm install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace \
  -f base-values.yaml \
  -f prod-probes.yaml \
  --set serviceMonitor.interval=30s
```

### 4. Check Deployed Release Status

```bash
# Check status of deployed release
helm status https-wrench --namespace monitoring

# List releases in namespace
helm list --namespace monitoring

# View current deployed release values
helm get values https-wrench --namespace monitoring

# View full rendered manifests
helm get manifest https-wrench --namespace monitoring
```

### 5. Upgrade or Idempotent Deploy (`upgrade --install`)

**Upgrade an existing release:**

```bash
helm upgrade https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  -f my-probes-values.yaml
```

**Idempotent deploy (Install if missing, Upgrade if present):**

```bash
helm upgrade --install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace \
  -f my-probes-values.yaml
```

The running `https-wrench` pod will automatically reload modified probes without downtime.

### 6. Pull and Extract OCI Chart Locally (Optional)

To download and extract the raw chart source files locally for inspection or local testing:

```bash
helm pull oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0 --untar
```

## Configuration Parameters

| Parameter | Description | Default |
| :--- | :--- | :--- |
| `replicaCount` | Number of pod replicas | `1` |
| `image.repository` | Container image repository | `ghcr.io/xenos76/https-wrench` |
| `image.tag` | Image tag (defaults to `Chart.appVersion`) | `v0.17.0` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `service.port` | Port exposed by the Service | `9090` |
| `serviceMonitor.enabled` | Deploy Prometheus ServiceMonitor | `true` |
| `serviceMonitor.interval` | Prometheus scrape interval | `15s` |
| `prometheusRule.enabled` | Deploy PrometheusRule alerts | `false` |
| `prometheusRule.labels` | Discovery labels for Prometheus Operator | `{}` |
| `gateway.enabled` | Deploy a Gateway resource | `false` |
| `gateway.apiVersion` | `gateway.networking.k8s.io/v1` or `networking.istio.io/v1beta1` | `gateway.networking.k8s.io/v1` |
| `virtualService.enabled` | Deploy Istio VirtualService | `false` |
| `reload.triggerChecksumAnnotation` | Force rolling restart on ConfigMap update | `false` |
| `config` | Native `https-wrench` YAML configuration | *(see values.yaml)* |

## Changelog

See [CHANGELOG.md](../CHANGELOG.md#https-wrench) for release history and version details.

## For AI Agents

Refer to [AGENTS.md](./AGENTS.md) for architectural guidelines, constraints, and validation instructions.
