# frozen_string_literal: true

class SampleManifestAsset < ApplicationRecord
  belongs_to :sample_manifest, optional: false
  belongs_to :asset, optional: false

  validates :sanger_sample_id, presence: true
  delegate :human_barcode, to: :asset
end
