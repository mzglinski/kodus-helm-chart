.PHONY: docs docs-check

# renovate: datasource=github-releases depName=norwoodj/helm-docs
HELM_DOCS_VERSION ?= 1.14.2
HELM_DOCS ?= ./.bin/helm-docs

docs:
	@mkdir -p .bin
	@command -v $(HELM_DOCS) >/dev/null 2>&1 || \
		curl -fsSL "https://github.com/norwoodj/helm-docs/releases/download/v$(HELM_DOCS_VERSION)/helm-docs_$(HELM_DOCS_VERSION)_Linux_x86_64.tar.gz" | tar xz -C .bin
	$(HELM_DOCS) --chart-search-root=.

docs-check: docs
	git diff --exit-code chart/README.md
