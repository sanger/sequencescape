# frozen_string_literal: true

# A QC Assay identifies a set of qc results which were performed
# together. It allows for attributes which are associated with each other
# such as loci_passed and loci_tested to be coupled
class QcAssay < ApplicationRecord
  # We don't want to remove qc_assays if they have results
  has_many :qc_results, dependent: :restrict_with_exception

  after_create :generate_events

  private

  def generate_events
    BroadcastEvent::QcAssay.generate_events(self)
  end
end
