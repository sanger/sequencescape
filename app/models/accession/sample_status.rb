# frozen_string_literal: true

# Designed to track the status of Sample accessioning requests in order to provide feedback to users.
# It could be expanded to track other accessionable types in the future.
#
# Associations:
#  belongs_to :sample - The sample being accessioned
#
# Attributes:
#  sample_id: integer - The ID of the sample being accessioned
#  status: string - The current status of the accessioning request (eg: 'queued', 'failed')
#  message: text - Any message associated with the status (eg: error messages)

class Accession::SampleStatus < ApplicationRecord
  belongs_to :sample, class_name: '::Sample'

  validates :status, presence: true, inclusion: { in: %w[queued processing failed aborted] }

  # Creates a new Accession::SampleStatus record for the given sample with the specified status.
  #
  # @param sample [Sample] The sample for which to create the status record.
  # @param status [String] The status to set (default: 'queued').
  # @param message [String, nil] An optional message to associate with the status.
  # @return [Accession::SampleStatus] The newly created status record.
  def self.create_for_sample(sample, status = 'queued', message = nil)
    create!(sample:, status:, message:)
  end

  # Returns the most recent Accession::SampleStatus record for the given sample, optionally filtered by status.
  #
  # @param sample [Sample] The sample for which to find the latest status.
  # @param status [String, nil] Optional status to filter by (e.g., 'queued', 'failed').
  # @return [Accession::SampleStatus] The latest status record for the sample.
  # @raise [ActiveRecord::RecordNotFound] If no matching status record exists for the sample and status.
  def self.find_latest!(sample, status: nil)
    scope = where(sample:)
    scope = scope.where(status:) if status
    scope.order(created_at: :desc).first!
  end

  # Updates the most recent Accession::SampleStatus record for the given sample, optionally filtered by status.
  #
  # @param sample [Sample] The sample for which to update the latest status.
  # @param status [String, nil] Optional status to filter by (e.g., 'queued', 'failed').
  # @param attributes [Hash] The attributes to update on the status record.
  # @return [Accession::SampleStatus] The updated status record.
  # @raise [ActiveRecord::RecordNotFound] If no matching status record exists for the sample.
  def self.find_latest_and_update!(sample, status: nil, attributes: {})
    # Wrap in a transaction to prevent race conditions
    transaction do
      status_record = find_latest!(sample, status:)
      status_record.update!(attributes)
      status_record
    end
  end
end
