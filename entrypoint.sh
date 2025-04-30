#!/usr/bin/env bash

#
# This script waits 15 seconds for connection with the database,
# then it will reset the database if RESET_DATABASE is "true"
# and after that will start the we server
set -o errexit
set -o pipefail
set -o nounset

TIMEOUT=120

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

# Install any missing packages - very useful for development without rebuilding the image
bundle install

./wait_for_connection.sh "${DBHOST}" "${DBPORT}" "${TIMEOUT}"

if [ "${RESET_DATABASE:-}" = "true" ]; then
  echo "Resetting database"
  bundle exec rake db:reset
fi

# Build the static web assets
if [ "${PRECOMPILE_ASSETS:-}" = "true" ]; then
  bundle exec rails assets:precompile
fi

echo "Starting service"
exec bundle exec rails s -b 0.0.0.0
