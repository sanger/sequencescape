# frozen_string_literal: true

# Joins a support action to any affected records for logging purposes
class SupportActionsResource < ApplicationRecord
  belongs_to :support_action
  belongs_to :resource, polymorphic: true
end
