# AGENTS.md — `https-wrench` Chart Guide

This guide encodes architectural decisions, constraints, and verification workflows for AI coding agents maintaining or modifying this Helm chart.

---

## 1. Chart Purpose & Operational Mode

`https-wrench` packages [https-wrench](https://github.com/xenOs76/https-wrench) (version >= 0.17.0) to run as a continuous synthetic probe runner and metrics exporter in Kubernetes.

- **Execution Command:** The container runs `/https-wrench requests --config /etc/https-wrench/config.yaml --observe`. Because the upstream container image is built `FROM scratch` with the binary located at `/https-wrench`, specifying `/https-wrench` as an absolute path is required (there is no shell or `/usr/bin` in `$PATH`).
- **Primary Scrape Port:** Exposes an internal HTTP server on port `9090` (named `metrics`) at path `/metrics`.
- **Target Workloads:** Evaluates internal and edge HTTPS endpoints, validating status codes, response headers, TLS cert validity, and regex assertions.

---

## 2. Configuration & Live Reload Mechanics

`https-wrench` supports on-the-fly reload without dropping connections or requiring pod restarts.

### 1. Inotify File Watcher (Default)
- **Mechanism:** When `.Values.config` is modified via Helm upgrade, the rendered ConfigMap updates. Kubelet asynchronously updates the symlink target inside `/etc/https-wrench/`.
- **CRITICAL CONSTRAINT:** The volume mount MUST NOT use `subPath`. Kubernetes disables live file updates for `subPath` volume projections. Mounting the entire directory (`mountPath: /etc/https-wrench`) preserves the `..data` symlink rotation and allows `https-wrench`'s file watcher to detect updates immediately.

### 2. HTTP POST Reload Endpoint
- **Mechanism:** `POST http://<pod-ip>:9090/-/reload`.
- **Security:** If `config.observability.pull.reloadToken` is set in values, include header `Authorization: Bearer <token>`.

### 3. Checksum Rolling Restarts (Optional)
- Setting `.Values.reload.triggerChecksumAnnotation: true` calculates `sha256sum` over `configmap.yaml` and embeds it into `spec.template.metadata.annotations["checksum/config"]`. This forces a standard Kubernetes rolling update if immediate pod recreation is desired.

---

## 3. Schema & Validation Contracts

Deterministic verification is mandatory. The chart provides `values.schema.json`:
- **Local Validation:** Validates image configuration, replica count, ports, ServiceMonitor, Gateway, and VirtualService fields.
- **Upstream Validation:** Under `properties.config`, the schema references:
  `$ref: "https://raw.githubusercontent.com/xenOs76/https-wrench/refs/heads/main/https-wrench.schema.json"`
  Every probe entry in `config.requests[]` is validated against the official upstream schema.

### Core Configuration Constraints:
- `verbose` is **required** by schema (boolean).
- `requests` is **required** by schema (array).
- Each request must define `name` (string) and `hosts` (non-empty array).
- Each entry in `hosts[].uriList` **must begin with a leading `/`**.
- `transportOverrideUrl` must match regex `^https://`.

---

## 4. Ingress & Observability CRD Standards

### Prometheus ServiceMonitor & PrometheusRule
- **ServiceMonitor:** Uses API group `monitoring.coreos.com/v1`. Targets port `metrics` on the chart Service. Discovery labels are configurable via `.Values.serviceMonitor.labels` (e.g. `release: kube-prometheus-stack`).
- **PrometheusRule:** Uses API group `monitoring.coreos.com/v1`. Generates alerts for probe failures (`HttpsWrenchProbeFailed`), certificate expiration warnings/criticals (`HttpsWrenchCertExpiringSoonWarning`, `HttpsWrenchCertExpiringSoonCritical`), invalid TLS certificates (`HttpsWrenchCertInvalid`), and remote push failures (`HttpsWrenchPushTelemetryErrors`). Discovery labels are configurable via `.Values.prometheusRule.labels`.

### Gateway & Istio VirtualService
- **Gateway:** Toggled via `.Values.gateway.enabled`. Supports both Kubernetes Gateway API (`gateway.networking.k8s.io/v1`) and Istio Gateway (`networking.istio.io/v1beta1`) via `.Values.gateway.apiVersion`.
- **VirtualService:** Toggled via `.Values.virtualService.enabled`. Attaches to mesh gateways (defaults to `istio-system/gateway-priv-os76`) to expose the metrics endpoint externally or to cross-namespace scrapers.

### Kubernetes NetworkPolicy
- **NetworkPolicy:** Toggled via `.Values.networkPolicy.enabled`. Uses standard `networking.k8s.io/v1`.
- Enforces ingress isolation on the pod's metrics endpoint (defaults to port `9090` or named port `metrics`).
- Enforces egress rules for essential DNS resolution (UDP/TCP port 53 permits traffic to any destination by default as its `to` list is omitted; restricting DNS to CoreDNS requires a configured `to` selector), outbound synthetic HTTP/HTTPS probes (ports 80 and 443 with IMDS `169.254.169.254/32` blocked), and optional telemetry push.

---

## 5. Verification Commands for Agents

Before completing any task modifying this chart, execute:

```bash
# 1. Lint the chart (triggers values.schema.json validation)
helm lint https-wrench

# 2. Dry-run template generation with defaults
helm template test-wrench https-wrench

# 3. Dry-run template generation with NetworkPolicy and all CRDs toggled on
helm template test-wrench https-wrench \
  --set networkPolicy.enabled=true \
  --set serviceMonitor.enabled=true \
  --set virtualService.enabled=true \
  --set gateway.enabled=true
```
