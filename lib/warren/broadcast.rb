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

    def close
      @bun_channel.close
    end

    private

    def exchange
      raise StandardError, 'No exchange configured' if @exchange_name.nil?

      @exchange ||= @bun_channel.topic(@exchange_name, auto_delete: false, durable: true)
    end
  end

  #
  # Creates a warren but does not connect.
  #
  # @param [Hash] server Server config options passes straight to Bunny
  # @param [String] exchange The name of the exchange to connect to
  # @param [Integer] pool_size The connection pool size
  def initialize(server: {}, exchange:, pool_size: 14)
    @server = server
    @exchange_name = exchange
    @pool_size = pool_size
  end

  #
  # Opens a connection to the RabbitMQ server. Will need to be re-initialized after forking.
  #
  # @return [true] We've connected!
  #
  def connect
    reset_pool
    start_session
  end

  #
  # Closes the connection. Call before forking to avoid leaking connections
  #
  #
  # @return [true] We've disconnected
  #
  def disconnect
    close_session
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
    with_chanel { |chanel| chanel << message }
    self
  end

  private

  def session
    @session ||= Bunny.new(@server)
  end

  def connection_pool
    @connection_pool ||= start_session && ConnectionPool.new(size: @pool_size, timeout: 5) do
      Channel.new(session.create_channel, exchange: @exchange_name)
    end
  end

  def start_session
    session.start
    true
  end

  def close_session
    reset_pool
    @session&.close
    @session = nil
  end

  def reset_pool
    @connection_pool&.shutdown { |ch| ch.close }
    @connection_pool = nil
  end
end
