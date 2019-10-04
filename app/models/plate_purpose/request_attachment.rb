module PlatePurpose::RequestAttachment
  # Performs the standard transition_to of the containing class and then
  # connects the upstream and downstream requests to matching wells
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    super
    connect_requests(plate, state, contents)
  end

  def connect_requests(plate, state, contents = nil)
    return unless state == connect_on

    wells = plate.wells
    wells = wells.located_at(contents) if contents.present?

    wells.include_stock_wells.include_requests_as_target.includes(:transfer_requests_as_target).find_each do |target_well|
      source_wells = target_well.stock_wells
      submission_ids = target_well.transfer_requests_as_target.map(&:submission_id)

      source_wells.each do |source_well|
        # We may have multiple requests out of each well, however we're only concerned
        # about those associated with the active submission.
        upstream = source_well.requests.detect do |r|
          submission_ids.include?(r.submission_id)
        end

        # We need to find the downstream requests BEFORE connecting the upstream
        # This is because submission.next_requests tries to take a shortcut through
        # the target_asset if it is defined.
        upstream.next_requests.each { |ds| ds.update!(asset: target_well) } if connect_downstream

        # In some cases, such as the Illumina-C pipelines, requests might be
        # connected upfront. We don't want to touch these.
        next unless upstream.target_asset.nil?

        upstream.update!(target_asset: target_well)
        upstream.pass!
      end
    end
  end

  def self.included(base)
    base.class_eval do
      class_attribute :connect_on
      class_attribute :connect_downstream
    end
  end
end
