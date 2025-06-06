PROJECT_REL_DIR=./
include ${PROJECT_REL_DIR}common.mk

## IMPORTANT: THIS IS A PARENT DIR. MAKE SURE TO RUN MAKE IN THE SUBMODULES FIRST.
BUILD_IMAGE_PROJECT_DIR=/go/src/${PROJECT_PATH}
BUILD_WORKDIR=${BUILD_IMAGE_PROJECT_DIR}

# Find proto files in API directory
PROTO_SOURCE_FILES := $(shell find api -name '*.proto')
$(info Found proto files: ${PROTO_SOURCE_FILES})

# Generate files will be in generated directory
PROTO_FILES := $(patsubst api/%.proto,generated/%.pb.go,$(PROTO_SOURCE_FILES))
$(info Will generate: ${PROTO_FILES})
ARTIFACTS=${PROTO_FILES}

# build if PROTO_SOURCE_FILES have changed or generated files are missing
${ARTIFACTS}: ${PROTO_SOURCE_FILES}
	@for dir in $(shell find submodules -maxdepth 1 -mindepth 1 -type d); do \
		if [ ! -d "$$dir/generated" ]; then \
			echo "Error: $$dir/generated directory not found."; \
			echo ""; \
			echo "Please run 'make' in $$dir first."; \
			echo ""; \
			echo "After building the submodule, return here and run make again."; \
			exit 1; \
		fi \
	done
	${DOCKER_RUN} \
		-u ${DOCKER_USER} \
		-v ${DOCKER_PROJECT_DIR}:${BUILD_IMAGE_PROJECT_DIR} \
		--mount type=tmpfs,destination=/.cache \
		-e PROJECT_PATH="${PROJECT_PATH}" \
		-e VERSION="${VERSION}" \
		-w ${BUILD_WORKDIR} \
		${BUILD_IMAGE}
