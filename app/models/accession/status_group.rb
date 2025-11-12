# frozen_string_literal: true

# Designed to track the groups of accessioning requests to provide feedback to users.
# Feedback is provided once all items within a given status group have been processed.
#
# Attributes:
#  accession_group_type: string - The type of accession group, if applicable (e.g., 'SampleManifest', 'Study')
#  accession_group_id: integer - The ID of the accession group, if applicable

class Accession::StatusGroup < ApplicationRecord
  # Polymorphic association of the status group (e.g., SampleManifest, Study)
  belongs_to :accession_group, polymorphic: true, optional: true

  has_many :statuses, class_name: 'Accession::Status', dependent: :destroy

  # Returns true if all statuses in the group have been processed (not queued)
  def all_statuses_processed?
    statuses.where(status: 'queued').empty?
  end
end
