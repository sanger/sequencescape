# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Event::AssetDescriptorUpdateEvent
  def self.included(base)
    base.after_create(:update_descriptors_for_asset, if: ->(event) { event.eventful.is_a?(Asset) and not event.descriptor_key.blank? })
  end

  def update_descriptors_for_asset
    eventful.add_descriptor(Descriptor.new(name: descriptor_key, value: content))
    eventful.save!
  end
end
