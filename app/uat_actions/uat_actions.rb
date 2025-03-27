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

  # List of categories to group UatActions by, in the order they should be displayed
  # This is used only for display purposes and can be altered as required
  CATEGORY_LIST = %i[setup_and_test generating_samples auxiliary_data quality_control uncategorised].freeze

  class_attribute :title, :description, :category, :message
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

    # Default category should one not be provided
    def category
      UatActions::CATEGORY_LIST.last
    end

    # Returns a hash of all registered uat_actions grouped by category and sorted
    def grouped_and_sorted_uat_actions
      # raise error if any categories are not in the list
      all.each do |uat_action|
        unless CATEGORY_LIST.include?(uat_action.category)
          raise "Category '#{uat_action.category}' from '#{uat_action}' is not in the list" \
                  " of categories #{CATEGORY_LIST}"
        end
      end

      all.group_by(&:category).sort_by { |category, _| CATEGORY_LIST.index(category) }
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

      @form_fields << UatActions::FormField.new(options.merge(attribute:, type:))
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

  delegate :form_fields, to: :class

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
