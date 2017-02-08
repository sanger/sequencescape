# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module Event::RequestDescriptorUpdateEvent
  def self.included(base)
    base.after_create(:update_metadata_for_request, if: ->(event) { event.eventful.is_a?(Request) and not event.descriptor_key.blank? })
  end

  def pass_or_fail_event?
    ['fail', 'pass'].include?(family)
  end

  def library_creation_descriptor?
    ['library_creation_complete', 'multiplexed_library_creation'].include?(descriptor_key)
  end

  def set_request_metadata
    eventful.request_metadata[descriptor_key] = content
    eventful.request_metadata.save!
  end

  def update_metadata_for_request
    request = eventful
    set_request_metadata unless pass_or_fail_event?

    if request.failed? or request.cancelled?
      set_request_metadata
      return
    end

    return if pass_or_fail_event?
    if library_creation_descriptor?
      request.pass!
    else
      request.start!
    end
  end
end
