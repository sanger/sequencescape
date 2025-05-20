# frozen_string_literal: true

module Core::Logging
  def debug(message)
    Rails.logger.debug(add_api_context(message))
  end

  def info(message)
    Rails.logger.info(add_api_context(message))
  end

  def error(message)
    Rails.logger.error(add_api_context(message))
  end

  def low_level(*args)
    # debug(*args)
  end

  private

  # Add API context to the log message.
  #
  # If the method is called on a class, it uses the class name directly.
  # If called on an instance, it uses the name of the instance's class.
  #
  # @param message [String] The log message to be formatted.
  # @return [String] The formatted log message with API context.
  #   Example: "API(ClassName): Log message"
  def add_api_context(message)
    self_name = is_a?(Class) ? self : self.class.name
    "API(#{self_name}): #{message}"
  end
end
