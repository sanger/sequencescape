# frozen_string_literal: true

# A request received by an API operations endpoint, such as the Sapio
# operations endpoint, and its processing progress.
#
# The calling system's request ID (external_id) and the request body
# (payload) are stored exactly as received. The payload digest identifies
# the payload, so a repeated request can be told apart from a changed one.
#
# The status starts as queued. Later stories add the other values, such as
# completed and failed. response_delivered_at records when the response was
# delivered to the calling system, and is null until then.
class ApiOperation < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :api_application, optional: false

  validates :external_id, :operation_type, :payload, :status, presence: true
  validates :payload_digest, presence: true, length: { is: 64 }

  # Saves an operation and queues its CoordinatorJob in one transaction, so
  # an operation never lacks its job.
  #
  # @param attributes [Hash] the operation's attributes
  # @return [ApiOperation] the saved operation
  def self.create_with_job!(**attributes)
    transaction do
      create!(**attributes).tap do |operation|
        Delayed::Job.enqueue(CoordinatorJob.new(operation.id))
      end
    end
  end
end
