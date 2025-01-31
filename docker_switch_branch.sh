#!/bin/bash
# Restart the container using the image tagged with the current Git branch name

# Set the use polling file watcher default to false, if not already set
if [ -z ${USE_POLLING_FILE_WATCHER+x} ]; then USE_POLLING_FILE_WATCHER="false"; fi

# Get the current branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
# Start the container using the image tagged with the current branch name
BRANCH_IMAGE_TAG=$BRANCH_NAME \
USE_POLLING_FILE_WATCHER=$USE_POLLING_FILE_WATCHER \
docker compose -f docker-compose-dev.yml up -d
