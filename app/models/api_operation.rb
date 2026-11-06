# frozen_string_literal: true

# A request received by an API operations endpoint, such as the Sapio
# operations endpoint, and its processing progress.
#
# The calling system's request ID (external_id) and the request body
# (payload) are stored exactly as received. The payload digest identifies
# the payload, so a repeated request can be told apart from a changed one.
#
# The status starts as queued and is one of the STATUSES. response_delivered_at records when the response was
# delivered to the calling system, and is null until then.
class ApiOperation < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :api_application, optional: false

  # The processing progress of an operation, stored as the string value
  STATUSES = {
    queued: 'queued', # api request received, job not yet started
    processing: 'processing', # api request received and job started
    completed: 'completed', # completed successfully
    completed_with_errors: 'completed_with_errors' # completed with errors
  }.freeze

  enum :status, STATUSES, default: :queued
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

  # Reports the operation's status back to the calling system by queuing a
  # CallbackJob. The job will POST the operation's external_id, operation_type,
  # status to the calling system, in one transaction.
  # This method is called after the operation is completed, so the status is either completed or completed_with_errors.
  # @return [void]
  def report_back_operation_status
    Delayed::Job.enqueue(CallbackJob.new(id))
  end
end
