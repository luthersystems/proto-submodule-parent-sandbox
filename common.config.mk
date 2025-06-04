# General project config for dockerized buf generation

PROJECT=proto-experiment
VERSION=0.1.0-SNAPSHOT

# Docker image version (using Luther BuildEnv)
BUILDENV_TAG=a8ebf90345ea3c6a0acc19a6fb0939f3dbe6d64c

# Build image full name (assuming BUILD_IMAGE_API is still configured somewhere centrally)
BUILD_IMAGE_API=luthersystems/buildenv-go-proto
BUILD_IMAGE=${BUILD_IMAGE_API}:${BUILDENV_TAG}