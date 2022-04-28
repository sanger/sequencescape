# frozen_string_literal: true
require_dependency 'broadcast_event/lab_event'

# Lab events are created as part of the traditional Sequencescape based pipelines
# they track the information supplied in each step, mostly in the form of descriptors:
# key value pairs.
# They can be associated with individual requests, or the batch as a whole.
# The information is mainly displayed on the batch summary screen, but also acts
# as a source of information for the FlowcellIO message
class LabEvent < ApplicationRecord
  include ActsAsDescriptable

  CHIP_BARCODE_STEPS = ['Cluster generation', 'Add flowcell chip barcode', 'Loading'].freeze

  belongs_to :batch
  belongs_to :user
  belongs_to :eventful, polymorphic: true, inverse_of: :lab_events

  scope :with_descriptor, ->(k, v) { where(['descriptors LIKE ?', "%#{k}: #{v}%"]) }

  scope :with_flowcell_barcode,
        ->(barcode) { where(description: CHIP_BARCODE_STEPS).with_descriptor('Chip Barcode', barcode) }

  delegate :flowcell, :eventful_studies, :samples, to: :eventful

  after_create :generate_broadcast_event

  def self.find_batch_id_by_barcode(barcode)
    batch_ids = with_flowcell_barcode(barcode).distinct.pluck(:batch_id)
    batch_ids.first if batch_ids.one?
  end

  def descriptor_value_for(name)
    descriptors.detect { |desc| desc.name.casecmp?(name.to_s) }&.value
  end

  def add_new_descriptor(name, value)
    add_descriptor Descriptor.new(name: name, value: value)
  end

  def generate_broadcast_event
    BroadcastEvent::LabEvent.create!(seed: self, user: user)
  end
end
