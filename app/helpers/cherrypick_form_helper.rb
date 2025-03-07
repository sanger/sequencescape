# frozen_string_literal: true

module CherrypickFormHelper
  # Create a form group specifically for the cherrypick-strategy radio buttons
  #
  # @param [String] object_name the name attribute of the radio button
  # @param [String] method the group the radio button belongs to
  # @param [String] field_value the value attribute of the radio button
  # @param [String] label_text the text to display in the label
  def cherrypick_strategy_radio_button(object_name, method, field_value, label_text, checked: false)
    content_tag(:div, class: 'form-group form-row') do
      label_tag("#{object_name}[#{method}]_#{field_value}", label_text, class: 'col-12 col-lg-8 col-form-label') +
        content_tag(:div, class: 'col-12 col-lg-4') do
          radio_button(object_name, method, field_value, { checked: checked, class: 'form-control text-right' })
        end
    end
  end

  # Creates a form group specifically for the cherrypick form with a label and a text field
  #
  # @param [String] fields the output of calling fields_for
  # @param [String] method the method to call on the form object
  # @param [String] label_text the text to display in the label
  # @param [String] default_text_field_value the default value of the text field
  # @param [Hash] options the options to pass to the text field
  # @return [String] the form group
  def cherrypick_form_group_text(fields, method, label_text, default_text_field_value, options = {})
    content_tag(:div, class: 'form-group form-row') do
      fields.label(method, label_text, class: 'col-12 col-lg-8 col-form-label') +
        content_tag(:div, class: 'col-12 col-lg-4') do
          fields.text_field(
            method,
            { value: default_text_field_value, class: 'form-control text-right' }.merge(options)
          )
        end
    end
  end
end
