
require_relative '../postman'

class Postman
  # Configures and wraps a Bunny Channel/Queue
  class Channel
    def initialize(client:, config:, type: :topic)
      @client = client
      @exchange_name = config[:exchange]
      @queue_name = config[:queue]
      @routing_keys = config[:routing_keys]
      @deadletter_exchange = config[:deadletter_exchange]
      @ttl = config[:ttl]
      @type = type
    end

    delegate :nack, :reject, :ack, to: :channel

    def subscribe(consumer_tag, &block)
      channel.prefetch(10)
      queue.subscribe(manual_ack: true, block: false, consumer_tag: consumer_tag, durable: true, &block)
    end

    # Publishes a message to the configured queue
    def publish(payload, options)
      options[:persistent] = true
      exchange.publish(payload, options)
    end

    # Ensures the queues and channels are set up to receive messages
    # keys: additional routing_keys to bind
    def activate!(keys: [])
      establish_bindings!
      keys.each { |key| add_routing_key(key) }
    end

    def add_routing_key(key)
      queue.bind(exchange, routing_key: key)
    end

    private

    def channel
      @channel ||= @client.create_channel
    end

    def exchange
      channel.public_send(@type, @exchange_name, auto_delete: false, durable: true)
    end

    def queue
      raise StandardError, 'No queue configured' if @queue_name.nil?
      channel.queue(@queue_name, arguments: queue_arguments, durable: true)
    end

    def queue_arguments
      config = { 'x-dead-letter-exchange' => @deadletter_exchange }
      config['x-message-ttl'] = @ttl if @ttl.present?
      config
    end

    def routing_keys
      if @type == :topic
        @routing_keys
      else
        [:topic]
      end
    end

    def establish_bindings!
      routing_keys.each { |key| add_routing_key(key) }
    end
  end
end
