# This contains details of the release of the application
# to remove hard coding throughout the application

# Parts of this file could be dynamically rewritten by
# Capistrano task / Git hooks on deployments / commits

require "ostruct"

RELEASE = OpenStruct.new

RELEASE.api_version = "0.6" # which API ?