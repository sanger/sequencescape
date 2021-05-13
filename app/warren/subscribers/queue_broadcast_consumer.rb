# frozen_string_literal: true

# Warren powered queue_broadcast_consumer consumers
# Handles the rebroadcast of short format message into their long form equivalent
# Takes messages from the psd.queue_broadcast queue
#
# == Example Message
# [Plate,1]
#
class Warren::Subscriber::QueueBroadcastConsumer < Warren::Subscriber::Base
  # == Handling messages
  # Message processing is handled in the {#process} method. The following
  # methods will be useful:
  #
  # @!attribute [r] payload
  #   @return [String] the payload of the message
  # @!attribute [r] delivery_info
  #   @return [Bunny::DeliveryInfo] mostly used internally for nack/acking messages
  #                                 http://rubybunny.info/articles/queues.html#accessing_message_properties_metadata
  # @!attribute [r] properties
  #   @return [Bunny::MessageProperties] additional message properties.
  #                             http://rubybunny.info/articles/queues.html#accessing_message_properties_metadata

  # Handles message processing. Messages are acknowledged automatically
  # on return from the method assuming they haven't been handled already.
  # In the event of an uncaught exception, the message will be dead-lettered.
  def process
    klass = json.first.constantize
    klass.find(json.last).broadcast
  rescue ActiveRecord::RecordNotFound
    # This may indicate that the record has been deleted
    debug "#{payload} not found."
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
end
