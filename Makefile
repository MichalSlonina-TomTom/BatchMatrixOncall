# Requirements: pandoc, mermaid-cli (brew install mermaid-cli  OR  npm install -g @mermaid-js/mermaid-cli)
.PHONY: all diagrams pdf architecture-pdf oncall-pdf clean

MMDC ?= $(shell command -v mmdc 2>/dev/null || echo npx mmdc)

all: diagrams pdf

diagrams:
	find diagrams -name "*.mmd" -exec sh -c 'f="$$1"; $(MMDC) -i "$$f" -o "$${f%.mmd}.png"' _ {} \;

pdf: architecture-pdf oncall-pdf

architecture-pdf: dist/architecture.pdf
dist/architecture.pdf:
	mkdir -p dist
	pandoc --toc --toc-depth=2 -V geometry:margin=2cm \
	  --pdf-engine=xelatex --resource-path=.:architecture \
	  architecture/01-introduction-and-goals.md \
	  architecture/02-architecture-constraints.md \
	  architecture/03-context-and-scope.md \
	  architecture/04-solution-strategy.md \
	  architecture/05-building-block-view.md \
	  architecture/06-runtime-view.md \
	  architecture/07-deployment-view.md \
	  architecture/08-concepts.md \
	  architecture/09-architecture-decisions.md \
	  architecture/10-quality-requirements.md \
	  architecture/11-technical-risks.md \
	  architecture/12-glossary.md \
	  -o dist/architecture.pdf

oncall-pdf: dist/oncall-guide.pdf
dist/oncall-guide.pdf:
	mkdir -p dist
	pandoc --toc -V geometry:margin=2cm --pdf-engine=xelatex \
	  oncall/setup.md \
	  oncall/runbooks/jumphost-pim.md \
	  oncall/runbooks/batch12-quotas.md \
	  oncall/runbooks/matrix-v2-quotas.md \
	  oncall/runbooks/traffic-manager.md \
	  oncall/runbooks/api-key-emergency.md \
	  oncall/runbooks/disk-expansion.md \
	  -o dist/oncall-guide.pdf

clean:
	rm -rf dist/ diagrams/*.png diagrams/*.svg
