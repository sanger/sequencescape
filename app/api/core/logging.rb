# frozen_string_literal: true

module Core::Logging
  # @deprecated This method does not appear to be used and will be removed in a future version.
  #   Use Rails.logger.debug directly instead.
  def debug(message)
    Rails.logger.debug(add_api_context(message))
  end

  # @deprecated This method does not appear to be used and will be removed in a future version.
  #   Use Rails.logger.debug directly instead.
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

  # Add API context to the log message from the instance's class name.
  #
  # @param message [String] The log message to be formatted.
  # @return [String] The formatted log message with API context.
  #   Example: "API(ClassName): Log message"
  def add_api_context(message)
    class_name = self.class.name
    "API(#{class_name}): #{message}"
  end
end
