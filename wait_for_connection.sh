#!/usr/bin/env bash

#
# This script waits TIMEOUT seconds for connection to HOST:PORT
# to be stablished and exit with 0 if success or 1 if error
set -o pipefail
set -o nounset

HOST=$1
PORT=$2
TIMEOUT=$3

TIMEOUT_END=$(($(date +%s) + TIMEOUT))
result=1
while [ $result -ne 0 ]; do
  echo "Waiting for connection to ${DBHOST}:${DBPORT}..."
  nc -w 1 -z "${HOST}" "${PORT}" > /dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    echo "Connected to ${DBHOST}:${DBPORT}."
    exit 0
  else
    if [ $(date +%s) -ge $TIMEOUT_END ]; then
      echo "Operation timed out" >&2
      exit 1
    fi
    sleep 1
  fi
done