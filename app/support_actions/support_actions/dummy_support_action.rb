# frozen_string_literal: true

# Handles a support action to
class SupportActions::DummySupportAction < SupportActions
  self.title = 'Dummy support action'

  # The description displays on the list of support actions to provide additional information
  self.description = 'A dummy action for dummies'

  # Form fields
  # form_field :resource_id, :select, label: 'Resource', help: 'Select a resource from the list',
  #               select_options: -> { Resource.scope.pluck(:name, :id) }
  # form_field :number_needed, :number_field, label: 'Number needed', help:
  # 'Fill in a number',
  #  options: { minimum: 1, maximum: 20 }
  form_field :comment, :text_field, label: 'Comment on this', help: 'Hello'

  #
  # Returns a default copy of the SupportAction which will be used to fill in the form
  #
  # @return [SupportActions::DummySupportAction] A default object for rendering a form
  def self.default
    new
  end

  #
  # [perform description]
  #
  # @return [Boolean] Returns true if the action was successful, false otherwise
  def perform
    # Called by the controller once the form is filled in. Add your actual actions here.
    # All the form fields are accessible as simple attributes.
    # Return true if everything works
    log('Testing')
    track_resource(Sample.first)
    true
  end
end
