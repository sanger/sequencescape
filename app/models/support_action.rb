# frozen_string_literal: true

# A support action represents a record of support work performed
class SupportAction < ApplicationRecord
  belongs_to :user
  has_many :support_actions_resources, dependent: :destroy

  delegate :description, :form_fields, to: :action_class

  # Tracks the action that was performed
  attribute :action

  # The SS version on which the action was performed
  attribute :version, default: Deployed::VERSION_COMMIT

  def action_class
    @action_class ||= SupportActions.find(action)
  end

  def action_object
    @action_object ||= action_class.new(action: self, user: user, **options || {})
  end

  def title
    action_class&.title || action
  end

  def perform
    transaction { action_object.save && save! }
  end

  def log(line)
    self.logs ||= +''
    self.logs += "#{line}\n"
  end

  def track_resource(resource)
    support_actions_resources.build(resource: resource)
  end
end
