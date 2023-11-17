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

  CATEGORY_LIST = %w[Tag Plate Tube Miscellaneous].freeze

  class_attribute :title, :description, :message
  self.message = 'Completed successfully'

  class << self
    #
    # Returns a list of all registered UatActions
    #
    # @return [Array<UatAction>] All registered UatActions
    #
    def all
      uat_actions.values
    end

    #
    # Find the UatAction identified by the id (Usually the class name parameterized)
    #
    # @param [String] id The id of the UatAction to find.
    #
    # @return [Class] A UatAction class
    #
    def find(id)
      uat_actions[id]
    end

    # The hash of all registered uat_actions
    def uat_actions
      @uat_actions ||= {}
    end

    # A logical grouping for display purposes
    def category
      # returns the first category in the list that matches the class name
      # or the last category in the list if no match is found
      CATEGORY_LIST.detect { |category| name.include?(category) } || CATEGORY_LIST.last
    end

    # Automatically called by UatActions classes to register themselves
    #
    # @param [Class] other Automatically called when inherited. Receives the descendant class
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

    #
    # Register a new {UatActions::FormField}. This will be automatically rendered by the UI
    # and any attributes will be available and instance attributes.
    #
    # @param [Symbol] attribute The attribute the field is linked to.
    # @param [Symbol] type The type of field to render. Should be something {ActionView::Helpers::FormBuilder}
    #                  responds to. @see https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html
    # @param [Hash] options Configure the attributes
    # @option options [String] :label The human readable label for the attribute, determines the field label
    # @option options [String] :help More verbose help text to explain the field (shown to the user)
    # @option options [Hash] :options Additional options passed through to the {ActionView::Helpers::FormBuilder} field
    #                                 itself. Eg. required, max, min, include_blank
    #
    # @return [void]
    #
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
Dir[File.join(__dir__, 'uat_actions', '*.rb')].each { |file| require_dependency file }
