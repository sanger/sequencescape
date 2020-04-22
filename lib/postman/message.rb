require 'active_record'
require 'active_support'
require 'active_support/core_ext'

class Postman
  # An artificial subclass of ActiveRecord::StatementInvalid that
  # just detects issues with the database connection
  class ConnectionMissing < ActiveRecord::StatementInvalid
    # Database connection messages indicated temporary issues connecting to the database
    # We handle them separately to ensure we can recover from network issues.
    DATABASE_CONNECTION_MESSAGES = [
      /Mysql2::Error: closed MySQL connection:/, # 2013,
      /Mysql2::Error: MySQL server has gone away/, # 2006
      /Mysql2::Error: Can't connect to local MySQL server through socket/, # , 2002, 2001, 2003, 2004, 2005,
      /Mysql2::Error::ConnectionError: Lost connection to MySQL server during query/, # Bugfix - First message was always lost
      /Mysql2::Error: MySQL client is not connected/
    ].freeze

    def self.===(other)
      other.is_a?(ActiveRecord::StatementInvalid) && database_connection_error?(other)
    end

    def self.database_connection_error?(exception)
      DATABASE_CONNECTION_MESSAGES.any? { |regex| regex.match?(exception.message) }
    end
  end

  InvalidPayload = Class.new(StandardError)

  # A message takes a rabbitMQ message, and handles its acknowledgement
  # or rejection.
  class Message
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
      debug 'Started message process'
      debug payload

      begin
        broadcast_payload
        ack
      rescue Postman::ConnectionMissing => e
        # We have some temporary database issues. Requeue the message and pause
        # until the issue is resolved.
        requeue(e)
        postman.pause!
      rescue StandardError => e
        deadletter(e)
      end

      debug 'Finished message process'
    end

    private

    def broadcast_payload
      klass = json.first.constantize
      klass.find(json.last).broadcast
    rescue ActiveRecord::RecordNotFound
      debug "#{payload} not found."
    rescue InvalidPayload => e
      warn e.message
    end

    def json
      @json ||= extract_json
    end

    def extract_json
      json = JSON.parse(payload)
      raise InvalidPayload, "Payload #{payload} is not an array" unless json.is_a?(Array)
      raise InvalidPayload, "Payload #{payload} is not the correct length" unless json.length == 2

      json
    rescue JSON::ParserError => e
      raise InvalidPayload, "Payload #{payload} is not JSON: #{e.message}"
    end

    def headers
      # Annoyingly it appears that a message with no headers
      # returns nil, not an empty hash
      metadata.headers || {}
    end

    def delivery_tag
      delivery_info.delivery_tag
    end

    def ack
      main_exchange.ack(delivery_tag)
    end

    # Reject the message and re-queue ready for
    # immediate reprocessing.
    def requeue(exception)
      warn "Re-queue: #{payload}"
      warn "Re-queue Exception: #{exception.message}"
      main_exchange.nack(delivery_tag, false, true)
      warn 'Re-queue nacked'
    end

    # Reject the message without re-queuing
    # Will end up getting dead-lettered
    def deadletter(exception)
      error "Deadletter: #{payload}"
      error "Deadletter Exception: #{exception.message}"
      main_exchange.nack(delivery_tag)
      error 'Deadletter nacked'
    end
  end
end
