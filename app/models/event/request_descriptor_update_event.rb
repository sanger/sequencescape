module Event::RequestDescriptorUpdateEvent
  def self.included(base)
    base.after_create(:update_metadata_for_request, :if => lambda { |event| event.eventful.is_a?(Request) and not event.descriptor_key.blank? })
  end

  def pass_or_fail_event?
    [ 'fail', 'pass' ].include?(self.family)
  end

  def library_creation_descriptor?
    [ 'library_creation_complete', 'multiplexed_library_creation' ].include?(self.descriptor_key)
  end

  def set_request_metadata
    eventful.request_metadata[ self.descriptor_key ] = self.content
    eventful.request_metadata.save!
  end

  def update_metadata_for_request
    request = self.eventful
    self.set_request_metadata unless self.pass_or_fail_event?

    if request.failed? or request.cancelled?
      self.set_request_metadata
      return
    end

    return if self.pass_or_fail_event?
    if self.library_creation_descriptor?
      request.pass!
    else
      request.start!
    end
  end
end

