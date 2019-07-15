AssetRefactor.when_refactored do
  class Lane < Labware; end
end

AssetRefactor.when_not_refactored do
  class Lane < Receptacle; end
end

# A Lane is a section of a Flowcell which is capable of containing one or more
# {Sample samples} for sequencing. Samples are represented by {Aliquot aliquots}
# which are distinguished by their distinct {Tag tags}.
# Currently flowcells can be approximated in Sequencescape by the {Batch} created
# at the end of the {SequencingPipeline}
class Lane
  include Api::LaneIO::Extensions
  include AliquotIndexer::Indexable
  include SingleReceptacleLabware

  # Not entirely sure this is correct, as really flowcells are the labware,
  # but we do rely on asset link to Lane. Currently aware of:
  # - Linking in {SpikedBuffer}, although this could be replaced with an actual transfer
  # - Finding lanes for a given plate on eg. the {PlateSummariesController plate summary}
  include AssetRefactor::Labware::Methods

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

  self.sample_partial = 'assets/samples_partials/lane_samples'

  extend Metadata

  has_metadata do
    custom_attribute(:release_reason, in: LIST_REASONS)
  end

  has_many :aliquot_indicies, inverse_of: :lane, class_name: 'AliquotIndex'

  scope :for_rebroadcast, -> { includes(requests_as_target: :batch) }

  def labwhere_location
    nil
  end

  def subject_type
    'lane'
  end

  def friendly_name
    name.presence || id # TODO: Maybe add location?
  end

  def source_labwares
    requests_as_target.map(&:asset).map(&:labware).uniq
  end

  def rebroadcast
    requests_as_target.each { |r| r.batch.try(:rebroadcast) }
  end

  def external_release_text
    return 'Unknown' if external_release.nil?

    external_release? ? 'Yes' : 'No'
  end
end
