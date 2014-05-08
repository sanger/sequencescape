begin
  require 'deployed_version'
rescue LoadError
  module Deployed
    VERSION_ID = 'LOCAL'
    VERSION_STRING = "#{File.split(Rails.root).last.capitalize} LOCAL [#{Rails.env}]"
  end
end
