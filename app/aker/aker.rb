# frozen_string_literal: true
##
# Aker namespace - This should hold all things Aker.
module Aker
  ##
  # All Aker tables need to be prefixed with Aker.
  # This method will autmoatically included as long as they are namespaced.
  def self.table_name_prefix
    'aker_'
  end
end
