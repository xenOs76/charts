# Changelog

All notable changes to the Helm charts in this repository will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## https-wrench

### [0.1.0] - 2026-09-25

#### Added
- **Initial Public OCI Release**: Published `https-wrench` chart version `0.1.0` (packaging `https-wrench` `v0.17.0`) to GitHub Container Registry (`ghcr.io/xenos76/charts/https-wrench`).
- **Scratch Container Compatibility**: Configured absolute binary invocation (`/https-wrench requests --config ... --observe`) to run upstream images built `FROM scratch`.
- **Zero-Downtime Configuration Reloading**:
  - Atomic directory projection on `/etc/https-wrench` without `subPath` to preserve Kubernetes symlink rotation for the Inotify watcher.
  - Optional HTTP `POST /-/reload` endpoint support with Bearer token authentication.
  - Optional rolling-update restart via SHA256 checksum annotation (`reload.triggerChecksumAnnotation`).
- **Schema Validation**: Dual-layer validation enforcing local chart parameters via `values.schema.json` and delegating probe configuration directly to upstream `https-wrench.schema.json`.
- **Prometheus Operator Integration**:
  - Prometheus `ServiceMonitor` (`monitoring.coreos.com/v1`) scraping port `9090` (`metrics`) at configurable intervals.
  - Automatic injection of `config.observability.metrics.customLabels.job` aligned with the `ServiceMonitor` release name via the `https-wrench.config` template helper.
  - Production-ready `PrometheusRule` alerting rules:
    - `HttpsWrenchProbeFailed`: Synthetic probe assertion or HTTP status code failures.
    - `HttpsWrenchCertExpiringSoonWarning`: TLS certificate expiry warning (< 30 days).
    - `HttpsWrenchCertExpiringSoonCritical`: TLS certificate expiry critical (< 7 days).
    - `HttpsWrenchCertInvalid`: Expired or invalid TLS certificates.
    - `HttpsWrenchPushTelemetryErrors`: Remote push telemetry failure tracking.
- **Routing & Ingress**:
  - Optional Gateway API (`gateway.networking.k8s.io/v1`).
  - Optional Istio `VirtualService` (`networking.istio.io/v1beta1`) with mesh gateway routing.
- **Hardened Security Context**:
  - Runs as unprivileged non-root user (`65534:65534`).
  - `readOnlyRootFilesystem: true`.
  - `allowPrivilegeEscalation: false`.
  - Dropped all Linux capabilities (`ALL`).
- **Automation & Tooling**:
  - Root `Makefile` for automated linting, dry-run template testing, packaging, and git release tagging.
  - Split GitHub Actions workflows:
    - `.github/workflows/lint.yml`: Automatic CI lint and template test for all charts on every push and PR.
    - `.github/workflows/release-https-wrench.yml`: Dedicated OCI publishing to GHCR restricted strictly to release tag pushes (`https-wrench-v*`) or manual dispatch.
