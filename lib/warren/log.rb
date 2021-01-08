#
# Class Warren::Log provides a dummy RabbitMQ
# connection pool for use during development
#
class Warren::Log
  class Channel # rubocop:todo Style/Documentation
    def <<(message)
      Rails.logger.info "Published: #{message.routing_key}"
      Rails.logger.debug "Payload: #{message.payload}"
    end
  end

  #
  # Provide API compatibility with the RabbitMQ versions
  # Do nothing in this case
  #
  def connect; end

  def disconnect; end

  #
  # Yields a Warren::Log::Channel
  #
  #
  # @return [void]
  #
  # @yieldreturn [Warren::Log::Channel] A rabbitMQ channel that logs messaged to the test warren
  def with_chanel
    yield Channel.new
  end

  def <<(message)
    with_chanel { |c| c << message }
  end
end
