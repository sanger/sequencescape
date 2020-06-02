require_dependency 'broadcast_event/lab_event'

class LabEvent < ApplicationRecord
  include ActsAsDescriptable

  CHIP_BARCODE_STEPS = ['Cluster generation', 'Add flowcell chip barcode', 'Loading'].freeze

  belongs_to :batch
  belongs_to :user
  belongs_to :eventful, polymorphic: true

  before_validation :unescape_for_descriptors

  scope :with_descriptor, ->(k, v) { where(['descriptors LIKE ?', "%#{k}: #{v}%"]) }

  scope :with_flowcell_barcode, ->(barcode) do
    where(description: CHIP_BARCODE_STEPS)
      .with_descriptor('Chip Barcode', barcode)
  end

  delegate :flowcell, :eventful_studies, :samples, to: :eventful

  after_create :generate_broadcast_event

  def unescape_for_descriptors
    self[:descriptors] = (self[:descriptors] || {}).to_h.transform_keys do |key|
      CGI.unescape(key)
    end
  end

  def self.find_batch_id_by_barcode(barcode)
    batch_ids = with_flowcell_barcode(barcode).distinct.pluck(:batch_id)
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
