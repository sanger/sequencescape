# frozen_string_literal: true

# Keeps track of sanger_sample_ids which have been allocated to a {SampleManifest}
# and associates them with the corresponding {Receptacle}
class SampleManifestAsset < ApplicationRecord
  belongs_to :sample_manifest, optional: false
  belongs_to :asset, optional: false
  belongs_to :sample, foreign_key: :sanger_sample_id,
                      primary_key: :sanger_sample_id, optional: true,
                      inverse_of: :sample_manifest_asset

  validates :sanger_sample_id, presence: true
  delegate :labware, to: :asset
  delegate :human_barcode, to: :labware, allow_nil: true

  # Returns the existing sample, or generates a new one if it doesn't exist
  def find_or_create_sample
    self.sample ||= create_sample
  end

  private

  def create_sample
    sample_manifest.create_sample_and_aliquot(sanger_sample_id, asset)
  end
end
