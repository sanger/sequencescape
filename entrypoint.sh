#!/usr/bin/env bash

#
# This script waits 15 seconds for connection with the database,
# then it will reset the database if RESET_DATABASE is "true"
# and after that will start the we server
#set -o errexit
set -o pipefail
set -o nounset


TIMEOUT=120

DBPORT="3306"
TIMEOUT_END=$(($(date +%s) + TIMEOUT))
result=1
while [ $result -ne 0 ]; do
  echo "Waiting for database connection..."
  nc -w 1 -z "${DBHOST}" "${DBPORT}" > /dev/null 2>&1
  result=$?
  if [ $result -eq 0 ]; then
    echo "Connected to database."
  else
    if [ $(date +%s) -ge $TIMEOUT_END ]; then
      echo "Operation timed out" >&2
      exit 1
    fi
    sleep 1
  fi
done

if [ "${RESET_DATABASE:-}" = "true" ]; then
  echo "Resetting database"
  bundle exec rake db:reset
fi

echo "Starting service"
exec bundle exec rails s -b 0.0.0.0
