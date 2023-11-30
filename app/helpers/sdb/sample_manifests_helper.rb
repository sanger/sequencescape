# frozen_string_literal: true
module Sdb::SampleManifestsHelper
  def count_labels
    {
      '1dtube' => 'Tubes required',
      'plate' => 'Plates required',
      'library' => 'Tubes required',
      'multiplexed_library' => 'Number of samples in library',
      'tube_rack' => 'Tube racks required'
    }
  end

  #
  # Returns suitable label text for the sample manifest count field
  # @todo Switch to just using I18n
  # @param asset_type [String] The asset_type / behaviour eg. '1dtube'
  #
  # @return [String] Suitable label text
  def count_label_for(asset_type)
    count_labels.fetch(asset_type, 'Count')
  end

  def submit_label_for(asset_type)
    asset_type == 'tube_rack' ? 'Create manifest' : 'Create manifest and print labels'
  end

  def purpose_label_for(asset_type)
    asset_type == 'tube_rack' ? 'Tube purpose' : 'Purpose'
  end

  def count_barcode_heading_for(asset_type)
    asset_type == 'tube_rack' ? 'Tube Racks' : 'Barcodes'
  end
end
