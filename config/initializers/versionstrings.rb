begin
  require 'deployed_version'
rescue LoadError
  module Deployed
    VERSION_ID = 'LOCAL'
    VERSION_STRING = "#{File.split(Rails.root).last.capitalize} LOCAL [#{Rails.env}]"
    RELEASE_NAME = 'Running locally'
  end
end
# Set the host-name on initialize
Deployed::HOSTNAME = Socket.gethostname
