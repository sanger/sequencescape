module Event::AssetDescriptorUpdateEvent
  def self.included(base)
    base.after_create(:update_descriptors_for_asset, if: ->(event) { event.eventful.is_a?(Asset) and not event.descriptor_key.blank? })
  end

  def update_descriptors_for_asset
    eventful.add_descriptor(Descriptor.new(name: descriptor_key, value: content))
    eventful.save!
  end
end
