# frozen_string_literal: true

# Keeps track of sanger_sample_ids which have been allocated to a {SampleManifest}
# and associates them with the corresponding {Receptacle}
class SampleManifestAsset < ApplicationRecord
  belongs_to :sample_manifest, optional: false
  belongs_to :asset, class_name: 'Receptacle', optional: false
  belongs_to :sample,
             foreign_key: :sanger_sample_id,
             primary_key: :sanger_sample_id,
             optional: true,
             inverse_of: :sample_manifest_asset

  validates :sanger_sample_id, presence: true
  delegate :labware, to: :asset
  delegate :human_barcode, to: :labware, allow_nil: true

  convert_labware_to_receptacle_for :asset

  # Returns the existing sample, or generates a new one if it doesn't exist
  def find_or_create_sample
    self.sample ||= create_sample
  end

  def aliquot
    asset.aliquots.detect { |a| a.sample_id == sample.id }
  end
  deprecate aliquot: 'Chromium manifests may have multiple aliquots. Please use aliquots instead.',
            deprecator: ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  def aliquots
    # JG: I'm afraid I'm not entirely sure why we're expecting aliquots of multiple samples in here
    # as multiplexed libraries still link to the 'library tube'. However I've decided to preserve
    # the behaviour of the original :aliquot implementation.
    asset.aliquots.select { |a| a.sample_id == sample.id }
  end

  private

  def create_sample
    sample_manifest.create_sample_and_aliquot(sanger_sample_id, asset)
  end
end
