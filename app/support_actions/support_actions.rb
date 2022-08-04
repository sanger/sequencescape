# frozen_string_literal: true

# require 'lib/form_actions'
#
# Base class for Uat Actions
# Adding a new action:
# 1) rails generate uat_action MyNewAction --description=My action description
#
# @author [jg16]
#
class SupportActions
  include FormActions
  attr_accessor :user, :id, :action
  self.to_partial_path = 'support_actions/entry'

  delegate :log, :track_resource, to: :action
end

# Load all uat_action modules so that they register themselves
Dir[File.join(__dir__, 'uat_actions', '*.rb')].each { |file| require_dependency file }
