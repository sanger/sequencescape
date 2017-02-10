# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

module Sdb::SampleManifestsHelper
  def count_labels
    {
      '1dtube'              => 'Tubes required',
      'plate'               => 'Plates required',
      'multiplexed_library' => 'Number of samples in library'
    }
  end

  def count_label_for(_asset_type)
    count_labels.fetch(params[:type], 'Count')
  end
end
