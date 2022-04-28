# frozen_string_literal: true
# A Lane is a section of a Flowcell which is capable of containing one or more
# {Sample samples} for sequencing. Samples are represented by {Aliquot aliquots}
# which are distinguished by their distinct {Tag tags}.
# Currently flowcells can be approximated in Sequencescape by the {Batch} created
# at the end of the {SequencingPipeline}
class Lane < Receptacle
  include Api::LaneIO::Extensions
  include AliquotIndexer::Indexable

  LIST_REASONS_NEGATIVE = [
    'Failed on yield but sufficient data for experiment',
    'Failed on quality but sufficient data for experiment',
    'Failed on adapter contamination but data sufficient for experiment'
  ].freeze

  LIST_REASONS_POSITIVE = [
    "Data doesn't contain any of the expected organism",
    "Data doesn't reflect the experiment",
    'GC bias in data set',
    'Multiplex tag problems in data set',
    'Unsure data source'
  ].freeze

  LIST_REASONS = [''] + LIST_REASONS_NEGATIVE + LIST_REASONS_POSITIVE

  self.sample_partial = 'assets/samples_partials/lane_samples'

  extend Metadata

  has_metadata { custom_attribute(:release_reason, in: LIST_REASONS) }

  has_many :aliquot_indicies, inverse_of: :lane, class_name: 'AliquotIndex'

  scope :for_rebroadcast, -> { includes(requests_as_target: :batch) }

  delegate :name, :name=, to: :labware

  def labware
    super || build_labware(sti_type: 'Lane::Labware', receptacle: self)
  end

  def friendly_name
    name.presence || id # TODO: Maybe add location?
  end

  def subject_type
    'lane'
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

  # Compatibility for v1 API maintains legacy 'type' for assets
  def legacy_asset_type
    sti_type
  end
end
