require 'active_support'
require 'active_support/core_ext'

class Postman
  # A message takes a rabbitMQ message, and handles its acknowledgement
  # or rejection.
  class Message
    # Database connection messages indicated temporary issues connecting to the database
    # We handle them separately to ensure we can recover from network issues.
    DATABASE_CONNECTION_MESSAGES = [
      /Mysql2::Error: closed MySQL connection:/, # 2013,
      /Mysql2::Error: MySQL server has gone away/, # 2006
      /Mysql2::Error: Can't connect to local MySQL server through socket/ # , 2002, 2001, 2003, 2004, 2005
    ].freeze

    attr_reader :delivery_info, :metadata, :payload, :postman

    delegate :warn, :info, :error, :debug, to: :logger
    delegate :main_exchange, to: :postman

    def logger
      Rails.logger
    end

    def initialize(postman, delivery_info, metadata, payload)
      @postman = postman
      @delivery_info = delivery_info
      @metadata = metadata
      @payload = payload
    end

    def process
      info 'Started message process'
      debug payload

      begin
        broadcast_payload
        main_exchange.ack(delivery_info.delivery_tag)
      rescue ActiveRecord::StatementInvalid => exception
        if database_connection_error?(exception)
          # We have some temporary database issues. Requeue the message and pause
          # until the issue is resolved.
          requeue(exception)
          postman.pause!
        else
          deadletter(exception)
        end
      rescue => exception
        deadletter(exception)
      end

      info 'Finished message process'
    end

    private

    def broadcast_payload
      json = JSON.parse(payload)
      raise StandardError, "Payload #{payload} is not an array" unless json.is_a?(Array)
      raise StandardError, "Payload #{payload} is not the correct length" unless json.length == 2
      klass = json.first.constantize
      klass.find(json.last).broadcast
    end

    def headers
      # Annoyingly it appears that a message with no headers
      # returns nil, not an empty hash
      metadata.headers || {}
    end

    def delivery_tag
      delivery_info.delivery_tag
    end

    def database_connection_error?(exception)
      DATABASE_CONNECTION_MESSAGES.any? { |regex| regex.match?(exception.message) }
    end

    def ack
      main_exchange.ack(delivery_tag)
    end

    # Reject the message and re-queue ready for
    # immediate reprocessing.
    def requeue(exception)
      warn "Re-queue: #{payload}"
      warn exception.message
      main_exchange.nack(delivery_tag, false, true)
    end

    # Reject the message without re-queuing
    # Will end up getting dead-lettered
    def deadletter(exception)
      error "Deadletter: #{payload}"
      error exception.message
      main_exchange.nack(delivery_tag)
    end
  end
end
