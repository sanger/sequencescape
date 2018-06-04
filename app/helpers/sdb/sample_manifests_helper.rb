
module Sdb::SampleManifestsHelper
  def count_labels
    {
      '1dtube'              => 'Tubes required',
      'plate'               => 'Plates required',
      'library'             => 'Tubes required',
      'multiplexed_library' => 'Number of samples in library'
    }
  end

  def count_label_for(_asset_type)
    count_labels.fetch(params[:asset_type], 'Count')
  end
end
