module Event::AssetDescriptorUpdateEvent
  def self.included(base)
    base.after_create(:update_descriptors_for_asset, :if => lambda { |event| event.eventful.is_a?(Asset) and not event.descriptor_key.blank? })
  end

  def update_descriptors_for_asset
    self.eventful.add_descriptor(Descriptor.new(:name => self.descriptor_key, :value => self.content))
    self.eventful.save!
  end
end
