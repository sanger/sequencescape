require 'linefeed_fix'
require 'csv'
module SampleManifest::InputBehaviour
  def self.included(base)
    base.class_eval do
      include ManifestUtil
      # Ensure that we can update the samples of a manifest
      has_many :samples
      accepts_nested_attributes_for :samples
    end
  end

  # updates the manifest barcode list e.g. after applying a foreign barcode
  def update_barcodes
    self.barcodes = labware.map(&:human_barcode)
    save!
  end
end
