#
# Class Warren::Broadcast provides a connection pool of
# threadsafe RabbitMQ channels for broadcasting messages
#
class Warren::Broadcast
  class Channel
    def initialize(bun_channel, exchange: nil)
      @bun_channel = bun_channel
      @exchange_name = exchange
    end

    def <<(message)
      exchange.publish(message.payload, routing_key: message.routing_key)
      self
    end

    private

    def exchange
      raise StandardError, "No exchange configured" if @exchange_name.nil?
      @exchange ||= @bun_channel.topic(@exchange_name, auto_delete: false, durable: true)
    end
  end
  #
  # Creates a warren but does not connect.
  #
  # @param [_] *_args Configuration arguments are ignored.
  #
  def initialize(url:, frame_max:, heartbeat:, exchange:)
    @session = Bunny.new(url, frame_max: frame_max, heartbeat: heartbeat)
    @exchange_name = exchange
  end

  #
  # Opens a connection to the RabbitMQ server. Will need to be re-initialized after forking.
  #
  #
  # @return [true] We've connected!
  #
  def connect
    @session.start
    true
  end

  #
  # Yields an exchange which gets returned to the pool on block closure
  #
  #
  # @return [void]
  #
  # @yieldreturn [Warren::Broadcast::Channel] A rabbitMQ channel that sends messages to the configured exchange
  def with_chanel(&block)
    connection_pool.with(&block)
  end

  #
  # Borrows a RabbitMQ channel, sends a message, and immediately returns it again.
  # Useful if you only need to send one message.
  #
  # @param [Warren::Message] message The message to broadcast. Must respond to #routing_key and #payload
  #
  # @return [Warren::Broadcast] Returns itself to allow chaining. But you're probably better off using #with_chanel inthat case
  #
  def <<(message)
    with_chanel {|chanel| chanel << message }
    self
  end

  private

  def connection_pool
    @connection_pool ||= ConnectionPool.new(size: 5, timeout: 5) do
      Channel.new(@session.create_channel, exchange: @exchange_name)
    end
  end
end
