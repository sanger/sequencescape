#!/bin/bash
if [ "$RESET_DATABASE" = "true" ]; then
  echo "Resetting database"
  bundle exec rake db:reset
fi

echo "Starting service"
bundle exec rails s -b 0.0.0.0
