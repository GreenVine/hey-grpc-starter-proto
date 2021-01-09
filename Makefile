.PHONY: build-proto
build-proto:
		scripts/manage-proto.sh build $(PROJECT_ROOT) $(DOCKER_IMAGE)

.PHONY: build-docker
build-docker:
		scripts/build-docker.sh $(PROJECT_ROOT)

.PHONY: format
format:
		scripts/manage-proto.sh format $(PROJECT_ROOT) $(DOCKER_IMAGE)

.PHONY: lint
lint:
		scripts/manage-proto.sh lint $(PROJECT_ROOT) $(DOCKER_IMAGE)

.PHONY: clean-proto
clean-proto:
		-scripts/manage-proto.sh clean $(PROJECT_ROOT) $(DOCKER_IMAGE)
		-rm -rf proto_gen

.PHONY: clean-docker
clean-docker:
		-docker rmi -f $(docker images -aq heygrpc-node-builder:local-build)
		-docker rmi -f $(docker images -aq heygrpc-base:local-build)
