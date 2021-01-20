.PHONY: build
build:
		scripts/manage-proto.sh build '$(PROJECT_ROOT)' '$(DOCKER_IMAGE)'

.PHONY: clean-build
clean-build: clean build

.PHONY: format
format:
		scripts/manage-proto.sh format '$(PROJECT_ROOT)' '$(DOCKER_IMAGE)'

.PHONY: full-build
full-build: clean-docker build-docker clean-build

.PHONY: full-format
full-format:
		scripts/manage-proto.sh full-format '$(PROJECT_ROOT)' '$(DOCKER_IMAGE)'

.PHONY: lint
lint:
		scripts/manage-proto.sh lint '$(PROJECT_ROOT)' '$(DOCKER_IMAGE)'

.PHONY: clean
clean:
		-scripts/manage-proto.sh clean '$(PROJECT_ROOT)' '$(DOCKER_IMAGE)'
		-rm -rf proto_gen
