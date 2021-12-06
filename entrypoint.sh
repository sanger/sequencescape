#!/usr/bin/env bash

#
# This script waits 15 seconds for connection with the database,
# then it will reset the database if RESET_DATABASE is "true"
# and after that will start the we server
set -o errexit
set -o pipefail
set -o nounset

TIMEOUT=120

./wait_for_connection.sh "${DBHOST}" "${DBPORT}" "${TIMEOUT}"

if [ "${RESET_DATABASE:-}" = "true" ]; then
  echo "Resetting database"
  bundle exec rake db:reset
fi

echo "Starting service"
exec bundle exec rails s -b 0.0.0.0
