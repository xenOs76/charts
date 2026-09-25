SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c

CHART ?= https-wrench
VERSION = $(shell grep '^version:' $(CHART)/Chart.yaml 2>/dev/null | awk '{print $$2}' | tr -d '"')
TAG = $(CHART)-v$(VERSION)

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target] [CHART=<chart-name>]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'

.PHONY: version
version: ## Display current version and tag for the specified CHART (default: https-wrench)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: Could not find version in $(CHART)/Chart.yaml" >&2; exit 1; \
	fi
	@echo "Chart:   $(CHART)"
	@echo "Version: $(VERSION)"
	@echo "Git Tag: $(TAG)"

.PHONY: check-clean
check-clean: ## Verify git working directory is clean
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "Error: Git working tree is dirty. Commit or stash changes before tagging." >&2; \
		git status -s; \
		exit 1; \
	fi

.PHONY: tag
tag: check-clean ## Create an annotated git tag for CHART (e.g. https-wrench-v0.1.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: Could not find version in $(CHART)/Chart.yaml" >&2; exit 1; \
	fi
	@if git rev-parse "$(TAG)" >/dev/null 2>&1; then \
		echo "Error: Git tag '$(TAG)' already exists locally." >&2; exit 1; \
	fi
	@echo "==> Creating annotated git tag: $(TAG)"
	git tag -a "$(TAG)" -m "Release $(CHART) $(VERSION)"
	@echo "Tag $(TAG) created successfully."
	@echo "To push this tag run: make push-tag CHART=$(CHART)"

.PHONY: push-tag
push-tag: ## Push the git tag for CHART to origin
	@if ! git rev-parse "$(TAG)" >/dev/null 2>&1; then \
		echo "Error: Git tag '$(TAG)' does not exist locally. Run 'make tag CHART=$(CHART)' first." >&2; exit 1; \
	fi
	@echo "==> Pushing git tag '$(TAG)' to origin"
	git push origin "$(TAG)"

.PHONY: release
release: tag push-tag ## Create and push git tag for CHART in one step

# Shortcuts for https-wrench
.PHONY: https-wrench-tag
https-wrench-tag: ## Shortcut: create git tag for https-wrench
	$(MAKE) tag CHART=https-wrench

.PHONY: https-wrench-push-tag
https-wrench-push-tag: ## Shortcut: push git tag for https-wrench
	$(MAKE) push-tag CHART=https-wrench

.PHONY: https-wrench-release
https-wrench-release: ## Shortcut: create and push git tag for https-wrench
	$(MAKE) release CHART=https-wrench

# Local validation targets
.PHONY: lint
lint: ## Run helm lint and template validation on CHART (using default values.yaml)
	@echo "==> Linting $(CHART) with default values.yaml"
	helm lint $(CHART)
	@echo "==> Validating template rendering for $(CHART)"
	helm template test $(CHART) > /dev/null

.PHONY: package
package: lint ## Package CHART locally into dist/
	@mkdir -p dist
	helm package $(CHART) --destination dist/
