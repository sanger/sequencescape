# frozen_string_literal: true
module Event::RequestDescriptorUpdateEvent
  def self.included(base)
    base.after_create(
      :update_metadata_for_request,
      if: lambda { |event| event.eventful.is_a?(Request) and event.descriptor_key.present? }
    )
  end

  def pass_or_fail_event?
    %w[fail pass].include?(family)
  end

  def library_creation_descriptor?
    %w[library_creation_complete multiplexed_library_creation].include?(descriptor_key)
  end

  def set_request_metadata
    eventful.request_metadata[descriptor_key] = content
    eventful.request_metadata.save!
  end

  def update_metadata_for_request
    set_request_metadata unless pass_or_fail_event?

    if request.failed? || request.cancelled?
      set_request_metadata
      return
    end

    return if pass_or_fail_event?

    library_creation_descriptor? ? request.pass! : request.start!
  end
end
