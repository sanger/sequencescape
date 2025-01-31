#!/bin/bash
# Build, tag and run the Docker image with the current Git branch name

# Set the chipset build argument to default, if not already set
if [ -z ${CHIPSET+x} ]; then CHIPSET="default"; fi

# Build the Docker image
docker compose build --build-arg CHIPSET=$CHIPSET --no-cache
# Get the current Git branch name
BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
# Tag the Docker image with the current Git branch name
docker tag sequencescape_local_image:latest sequencescape_local_image:$BRANCH_NAME
# Spin up the Docker containers
docker compose -f docker-compose-dev.yml up -d
