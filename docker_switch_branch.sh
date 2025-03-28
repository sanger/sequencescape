#!/bin/bash
# Restart the container using the image tagged with the current Git branch name

set -o errexit # Exit on error
set -o pipefail # Exit on pipeline error
set -o nounset # Exit if undeclared variable is used

# Set the reset database default to false, if not already set
if [ -z ${RESET_DATABASE+x} ]; then RESET_DATABASE="false"; fi

# Set the use polling file watcher default to false, if not already set
if [ -z ${USE_POLLING_FILE_WATCHER+x} ]; then USE_POLLING_FILE_WATCHER="false"; fi

# Set the precompile assets default to false, if not already set
if [ -z ${PRECOMPILE_ASSETS+x} ]; then PRECOMPILE_ASSETS="false"; fi

# Get the current branch name, replacing invalid characters with underscores, and converting to lowercase
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD | tr -cd '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')

# Check if the image for the current branch exists
if ! docker image inspect sequencescape_local_image:$BRANCH_NAME > /dev/null 2>&1; then
  echo "Docker image tagged '$BRANCH_NAME' does not exist. Run docker_build_and_tag_branch.sh first."
  exit 1
fi

echo "Using image for branch: $BRANCH_NAME"
# Start the container using the image tagged with the current branch name
RESET_DATABASE=$RESET_DATABASE \
USE_POLLING_FILE_WATCHER=$USE_POLLING_FILE_WATCHER \
PRECOMPILE_ASSETS=$PRECOMPILE_ASSETS \
BRANCH_IMAGE_TAG=$BRANCH_NAME \
docker compose -f docker-compose-dev.yml up -d
