module Sdb::SampleManifestsHelper
  def count_labels
    {
      '1dtube' => 'Tubes required',
      'plate' => 'Plates required',
      'library' => 'Tubes required',
      'multiplexed_library' => 'Number of samples in library'
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
end
