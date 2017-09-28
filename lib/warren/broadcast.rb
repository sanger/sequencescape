#
# Class Warren::Broadcast provides a connection pool of
# threadsafe RabbitMQ channels for broadcasting messages
#
class Warren::Broadcast
  class Channel
    def initialize(warren)
      @warren = warren
    end

    def <<(message)
      @warren._publish_(message)
    end
  end
  #
  # Creates a test warren with no messages.
  # Test warrens are shared across all threads.
  #
  # @param [_] *_args Configuration arguments are ignored.
  #
  def initialize(*_args)

  end

  def reinitialize; end

  def with_chanel
    yield Channel.new(self)
  end

  #
  # Do not use this directly. Intended solely for testing
  # invoked via Channel
  #
  def _publish_(message)
    Rails.logger.info "Published: #{message} with routing key: #{routing_key}"
  end
end
