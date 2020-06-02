# frozen_string_literal: true

#
# Base class for Uat Actions
# Adding a new action:
# 1) rails generate uat_action MyNewAction --description=My action description
#
# @author [jg16]
#
class UatActions
  include ActiveModel::Model

  class_attribute :title, :description, :message
  self.message = 'Completed successfully'

  class << self
    def all
      uat_actions.values
    end

    def find(id)
      uat_actions[id]
    end

    # The hash of all registered uat_actions
    def uat_actions
      @uat_actions ||= {}
    end

    # Called by UatActions classes to register themselves
    def inherited(other)
      # Register the form_fields of the parent class
      other.form_fields.concat(form_fields)
      UatActions.uat_actions[other.id] = other
    end

    def to_partial_path
      'uat_actions/entry'
    end

    def id
      name.demodulize.parameterize
    end

    def form_field(attribute, type, options = {})
      @form_fields ||= []
      attr_accessor attribute

      @form_fields << UatActions::FormField.new(options.merge(attribute: attribute, type: type))
    end

    def form_fields
      @form_fields ||= []
    end

    def permitted
      form_fields.map(&:attribute)
    end

    def default
      new
    end
  end

  def report
    @report ||= {}
  end

  def form_fields
    self.class.form_fields
  end

  def save
    valid? && ActiveRecord::Base.transaction { perform }
  end

  def perform
    errors.add(:base, 'This action has not been implemented.')
    false
  end
end

# Load all uat_action modules so that they register themselves
Dir[File.join(__dir__, 'uat_actions', '*.rb')].each do |file|
  require_dependency file
end
