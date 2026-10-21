# frozen_string_literal: true

# A request received by an API operations endpoint, such as the Sapio
# reception and work order endpoint, and its processing progress.
#
# The calling system's request ID (external_id) and the request body
# (payload) are stored exactly as received. The payload digest identifies
# the payload, so a repeated request can be told apart from a changed one.
#
# Each processing task has its own status, starting as pending. The overall
# status is derived from them, so it can't disagree with them.
class ApiOperation < ApplicationRecord
  include Uuid::Uuidable

  # The status of a task that hasn't started
  PENDING = 'pending'

  # The overall status before either task has started
  QUEUED = 'queued'

  # The overall status once a task has started
  PROCESSING = 'processing'

  belongs_to :api_application, optional: false

  validates :external_id, :operation_type, :payload, presence: true
  validates :payload_digest, presence: true, length: { is: 64 }
  validates :reception_status, :work_order_status, presence: true

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

  # The overall status, derived from the task statuses. Later stories add
  # the end states, such as completed and failed.
  #
  # @return [String] QUEUED or PROCESSING
  def status
    return QUEUED if [reception_status, work_order_status].all?(PENDING)

    PROCESSING
  end
end
