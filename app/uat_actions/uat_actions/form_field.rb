# frozen_string_literal: true

# Captures information about each form field and indicates how to render it
class UatActions::FormField
  include ActiveModel::Model

  attr_accessor :label, :type, :help, :attribute
  attr_writer :select_options, :options

  def select_options
    @select_options.respond_to?(:call) ? @select_options.call : @select_options
  end

  def options
    @options || {}
  end
end
