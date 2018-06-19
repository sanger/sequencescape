require_dependency 'broadcast_event/lab_event'

class LabEvent < ApplicationRecord
  include ActsAsDescriptable

  belongs_to :batch
  belongs_to :user
  belongs_to :eventful, polymorphic: true

  before_validation :unescape_for_descriptors

  scope :with_descriptor, ->(k, v) { where(['descriptors LIKE ?', "%#{k}: #{v}%"]) }

  scope :barcode_code, ->(barcode) do
    where(
      description: ['Cluster generation', 'Add flowcell chip barcode'],
      eventful_type: 'Request'
    ).where([
      'descriptors like ?',
      "%Chip Barcode: #{barcode}%"
    ])
  end

  delegate :flowcell, :eventful_studies, :samples, to: :eventful

  after_create :generate_broadcast_event

  def unescape_for_descriptors
    self[:descriptors] = (self[:descriptors] || {}).to_h.each_with_object({}) do |(key, value), hash|
      hash[CGI.unescape(key)] = value
    end
  end

  def self.find_batch_id_by_barcode(barcode)
    events = barcode_code(barcode)
    batch_ids = events.pluck(:batch_id).uniq
    batch_ids.first if batch_ids.one?
  end

  def descriptor_value_for(name)
    descriptors.each do |desc|
      if desc.name.casecmp(name.to_s).zero?
        return desc.value
      end
    end
    nil
  end

  def add_new_descriptor(name, value)
    add_descriptor Descriptor.new(name: name, value: value)
  end

  def generate_broadcast_event
    BroadcastEvent::LabEvent.create!(seed: self, user: user)
  end
end
