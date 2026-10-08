# Local prototype builds. See `make help`.
IMG ?= opencode

.PHONY: help build buildx run shell smoke clean

help: ## show targets
	@grep -E '^[a-z-]+:.*?##' $(MAKEFILE_LIST) | sed -E 's/^([a-z-]+):.*## /\1\t/' | expand -t12

build: ## build local image "opencode"
	docker build -t $(IMG) .

buildx: ## build arm64 locally + load (needs qemu)
	docker run --privileged --rm tonistiigi/binfmt --install arm64
	docker buildx inspect multi >/dev/null 2>&1 || docker buildx create --name multi --driver docker-container
	docker buildx build --builder multi --platform linux/arm64 --load -t $(IMG)-arm64 .
	docker run --rm --platform linux/arm64 $(IMG)-arm64 --version

run: ## run TUI, current dir mounted at /workspace
	docker run --init --rm -it -v $$PWD:/workspace $(IMG)

shell: ## bash shell, current dir mounted at /workspace
	docker run --init --rm -it -v $$PWD:/workspace $(IMG) bash

smoke: ## non-interactive check: version, tools, subcommand routing
	docker run --rm $(IMG) --version
	docker run --rm $(IMG) bash -c 'opencode --version && uv --version \
		&& for t in 7z curl git jq rg fzf file nano python3 unzip zip xz zstd sudo; do \
			command -v $$t >/dev/null || { echo "missing $$t"; exit 1; }; done && echo tools-ok'
	docker run --rm $(IMG) stats >/dev/null 2>&1 && echo subcommand-ok || echo routing-FAILED

clean: ## remove local images
	-docker rmi -f $(IMG) $(IMG)-arm64
