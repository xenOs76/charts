# Helm Charts Repository

Official multi-chart Helm repository maintained at [https://github.com/xenOs76/charts](https://github.com/xenOs76/charts).

All charts in this repository are packaged and published in **OCI format** to **GitHub Container Registry (GHCR)** under `ghcr.io/xenos76/charts`.

---

## Available Charts

| Chart | Version | Description | OCI Artifact | Docs | Changelog |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **https-wrench** | `0.1.0` | Synthetic HTTPS request probe runner and continuous observability service | `oci://ghcr.io/xenos76/charts/https-wrench` | [README](./https-wrench/README.md) | [Changelog](./CHANGELOG.md#https-wrench) |

---

## Using Charts from GitHub Container Registry (OCI)

### 1. Authenticate with GHCR (if required)

Public charts can be pulled anonymously. To authenticate (e.g. for CI/CD or private packages):

```bash
echo "$GITHUB_TOKEN" | helm registry login ghcr.io --username <github-username> --password-stdin
```

### 2. Inspect Chart Metadata and Values

Inspect metadata and default configuration directly from GHCR without cloning the repository:

```bash
# Show chart metadata
helm show chart oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0

# Show default values
helm show values oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0

# Show chart README
helm show readme oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0
```

### 3. Install or Upgrade Charts

**Basic Installation:**

```bash
helm install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace
```

**Idempotent Deploy (`upgrade --install`) with Custom Values:**

```bash
helm upgrade --install https-wrench oci://ghcr.io/xenos76/charts/https-wrench \
  --version 0.1.0 \
  --namespace monitoring \
  --create-namespace \
  -f custom-values.yaml
```

**Pull and Untar Chart Locally:**

```bash
helm pull oci://ghcr.io/xenos76/charts/https-wrench --version 0.1.0 --untar
```

---

## Development & Release Workflow

A root `Makefile` is provided to standardize chart linting, packaging, and tagging across multiple charts.

### Available Make Targets

```bash
# View all available targets
make help

# Show version and tag for the default or specified chart
make version CHART=https-wrench

# Lint chart and validate template rendering
make lint CHART=https-wrench

# Package chart locally into dist/
make package CHART=https-wrench

# Tag release (e.g. creates https-wrench-v0.1.0)
make tag CHART=https-wrench

# Push release tag to origin (triggers GitHub Actions release workflow)
make push-tag CHART=https-wrench

# Tag and push in one step
make release CHART=https-wrench

# Shortcuts for https-wrench
make release-https-wrench
```

---

## CI/CD Pipeline

Releases are automated via GitHub Actions in [.github/workflows/](.github/workflows/):
- Pushing a tag matching `<chart-name>-v*` (e.g. `https-wrench-v0.1.0`) triggers the corresponding chart release pipeline.
- The workflow lints the chart, validates template rendering, packages the chart, and pushes the OCI artifact to `oci://ghcr.io/xenos76/charts/<chart-name>`.
- Manual releases or version overrides can be triggered via `workflow_dispatch` in the GitHub Actions UI.

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── release-https-wrench.yml    # OCI release pipeline for https-wrench
├── https-wrench/                       # https-wrench Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   ├── values.schema.json
│   ├── README.md
│   └── templates/
├── .gitignore
├── Makefile                            # Multi-chart developer tooling
├── LICENSE
└── README.md                           # This file
```
