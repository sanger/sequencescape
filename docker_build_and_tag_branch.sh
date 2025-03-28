#!/bin/bash
# Build, tag and run the Docker image with the current Git branch name

set -o errexit # Exit on error
set -o pipefail # Exit on pipeline error
set -o nounset # Exit if undeclared variable is used

# Set the chipset build argument to default, if not already set
if [ -z ${CHIPSET+x} ]; then CHIPSET="default"; fi

# Set the reset database default to false, if not already set
if [ -z ${RESET_DATABASE+x} ]; then RESET_DATABASE="false"; fi

# Set the use polling file watcher default to false, if not already set
if [ -z ${USE_POLLING_FILE_WATCHER+x} ]; then USE_POLLING_FILE_WATCHER="false"; fi

# Set the precompile assets default to false, if not already set
if [ -z ${PRECOMPILE_ASSETS+x} ]; then PRECOMPILE_ASSETS="false"; fi

# Build the Docker image
docker compose build --build-arg CHIPSET=$CHIPSET --no-cache
# Get the current Git branch name, replacing invalid characters with underscores, and converting to lowercase
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')

echo "Tagging image with branch name '$BRANCH_NAME'"

# Tag the Docker image with the current Git branch name
docker tag sequencescape_local_image:latest sequencescape_local_image:$BRANCH_NAME
# Spin up the Docker containers
BRANCH_IMAGE_TAG=$BRANCH_NAME \
RESET_DATABASE=$RESET_DATABASE \
USE_POLLING_FILE_WATCHER=$USE_POLLING_FILE_WATCHER \
PRECOMPILE_ASSETS=$PRECOMPILE_ASSETS \
docker compose -f docker-compose-dev.yml up -d
