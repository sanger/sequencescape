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
    @messages = []
  end

  def reinitialize; end

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

  def debug!
    puts "#{@messages.count} messages"
    p @messages.map(&:routing_key)
  end

  #
  # Do not use this directly. Intended solely for testing
  # invoked via Channel
  #
  def _publish_(message)
    @messages << message
  end
end
