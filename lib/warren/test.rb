#
# Class Warren::Test provides provides a dummy RabbitMQ
# connection pool for use during development
#
class Warren::Test
  class Channel
    def initialize(warren)
      @warren = warren
    end

    def <<(message)
      @warren << message
    end
  end
  #
  # Creates a test warren with no messages.
  # Test warrens are shared across all threads.
  #
  # @param [_] *_args Configuration arguments are ignored.
  #
  def initialize(*_args)
    @messages = []
  end

  #
  # Provides API compatibility with the RabbitMQ versions
  # Does nothing in this case
  #
  def connect
  end

  #
  # Yields an exchange which gets returned to the pool on block closure
  #
  #
  # @return [void]
  #
  # @yieldreturn [Warren::Test::Channel] A rabbitMQ channel that logs messaged to the test warren
  def with_chanel
    yield Channel.new(self)
  end

  def clear_messages
    @messages = []
  end

  def last_message
    @messages.last
  end

  def message_count
    @messages.length
  end

  def messages_matching(routing_key)
    @messages.count { |message| message.routing_key == routing_key }
  end

  def <<(message)
    @messages << message
  end
end
