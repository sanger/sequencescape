module Sdb::SampleManifestsHelper

  def count_labels
    {
      '1dtube'              => 'Tubes required',
      'plate'               => 'Plates required',
      'multiplexed_library' => 'Number of samples in library'
    }
  end

  def count_label_for(asset_type)
    count_labels.fetch(params[:type],'Count')
  end

end
