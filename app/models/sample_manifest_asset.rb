# frozen_string_literal: true

class SampleManifestAsset < ApplicationRecord
  belongs_to :sample_manifest
  belongs_to :asset, class_name: 'Receptacle'

  delegate :human_barcode, to: :asset
end
