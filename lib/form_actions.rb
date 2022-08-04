# frozen_string_literal: true

# Used by UAT actions and Support actions to auto generate forms
module FormActions
  extend ActiveSupport::Concern
  include ActiveModel::Model

  included do
    class_attribute :title, :description, :message, :to_partial_path
    self.message = 'Completed successfully'
  end

  class_methods do
    #
    # Returns a list of all registered UatActions
    #
    # @return [Array<UatAction>] All registered UatActions
    #
    def all
      inherited_actions.values
    end

    #
    # Find the UatAction identified by the id (Usually the class name parameterized)
    #
    # @param [String] id The id of the UatAction to find.
    #
    # @return [Class] A UatAction class
    #
    def find(id)
      inherited_actions[id]
    end

    # The hash of all registered inherited_actions
    def inherited_actions
      @inherited_actions ||= {}
    end

    # Automatically called by UatActions classes to register themselves
    #
    # @param [Class] other Automatically called when inherited. Receives the descendant class
    def inherited(other)
      # Register the form_fields of the parent class
      other.form_fields.concat(form_fields)
      inherited_actions[other.id] = other
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
