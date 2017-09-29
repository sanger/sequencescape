#
# Class Warren::Log provides a dummy RabbitMQ
# connection pool for use during development
#
class Warren::Log
  class Channel
    def <<(message)
      Rails.logged.info "Published: #{message.routing_key}"
      Rails.logger.debug "Payload: #{message.payload}"
    end
  end

  #
  # Provides API compatibility with the RabbitMQ versions
  # Does nothing in this case
  #
  def connect
  end

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
end
