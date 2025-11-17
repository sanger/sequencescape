# frozen_string_literal: true

# Designed to track the status of Sample accessioning requests in order to provide feedback to users.
# It could be expanded to track other accessionable types in the future.
#
# Associations:
#  belongs_to :sample - The sample being accessioned
#  belongs_to :status_group - The group of accessioning requests this status belongs to
#
# Attributes:
#  sample_id: integer - The ID of the sample being accessioned
#  status: string - The current status of the accessioning request (eg: 'queued', 'failed')
#  message: text - Any message associated with the status (eg: error messages)

class Accession::Status < ApplicationRecord
  belongs_to :sample, class_name: '::Sample'
  belongs_to :status_group, class_name: 'Accession::StatusGroup', optional: true

  validates :status, presence: true, inclusion: { in: %w[queued processing failed aborted] }

  def self.create_for_sample(sample, status_group)
    create!(
      sample: sample,
      status_group: status_group,
      status: 'queued'
    )
  end

  def self.latest_for_sample!(sample)
    # raises ActiveRecord::RecordNotFound if not found
    where(sample:).order(created_at: :desc).first!
  end

  def mark_in_progress
    update(status: 'processing')
  end

  def mark_failed(message)
    update(status: 'failed', message: message)
  end

  def mark_aborted
    update(status: 'aborted') # update status, but preserve any existing message
  end
end
