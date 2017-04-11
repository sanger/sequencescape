# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Lane < Aliquot::Receptacle
  include Api::LaneIO::Extensions
  include LocationAssociation::Locatable
  include AliquotIndexer::Indexable

  def subject_type
    'lane'
  end

  LIST_REASONS_NEGATIVE = [
    'Failed on yield but sufficient data for experiment',
    'Failed on quality but sufficient data for experiment',
    'Failed on adapter contamination but data sufficient for experiment'

  ]

  LIST_REASONS_POSITIVE = [
    "Data doesn't contain any of the expected organism",
    "Data doesn't reflect the experiment",
    'GC bias in data set',
    'Multiplex tag problems in data set',
    'Unsure data source'
  ]

  LIST_REASONS = [''] + LIST_REASONS_NEGATIVE + LIST_REASONS_POSITIVE

  SAMPLE_PARTIAL = 'assets/samples_partials/lane_samples'

  extend Metadata
  has_metadata do
    attribute(:release_reason, in: LIST_REASONS)
  end

  has_one_as_child(:spiked_in_buffer, ->() { where(sti_type: 'SpikedBuffer') })

  has_many :aliquot_indicies, inverse_of: :lane, class_name: 'AliquotIndex'
end
