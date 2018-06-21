
class Lane < Receptacle
  include Api::LaneIO::Extensions
  include AliquotIndexer::Indexable

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
    custom_attribute(:release_reason, in: LIST_REASONS)
  end

  has_one :spiked_in_buffer_links, ->() { joins(:ancestor).where(assets: { sti_type: 'SpikedBuffer' }).direct }, class_name: 'AssetLink', foreign_key: :descendant_id
  has_one :spiked_in_buffer, through: :spiked_in_buffer_links, source: :ancestor

  has_many :aliquot_indicies, inverse_of: :lane, class_name: 'AliquotIndex'

  scope :for_rebroadcast, -> { includes(requests_as_target: :batch) }

  def subject_type
    'lane'
  end

  def friendly_name
    name # TODO: Maybe add location?
  end

  def source_labwares
    requests_as_target.map(&:asset).map(&:labware).uniq
  end

  def rebroadcast
    requests_as_target.each { |r| r.batch.try(:rebroadcast) }
  end
end
