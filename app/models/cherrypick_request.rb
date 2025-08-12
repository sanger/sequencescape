# frozen_string_literal: true

# This class is due to replace CherrypickForPulldownRequest
# A cherrypick represents a request to transfer material from one plate to another,
# usually for the purposes of consolidation for library creation.
class CherrypickRequest < CustomerRequest
  after_create :transfer_aliquots

  def on_started
    # Aliquots are transferred on creation by transfer requests.
    # This isn't ideal, but makes the transition easier without
    # slowing actual picks down.
  end

  def on_passed
    target_asset.transfer_requests_as_target.where(submission_id:).find_each(&:pass!)
  end

  def reduce_source_volume
    return unless asset.get_current_volume

    subtracted_volume = target_asset.get_picked_volume
    new_volume = asset.get_current_volume - subtracted_volume
    new_volume = 0 if new_volume.negative?
    asset.set_current_volume(new_volume)
  end

  private

  # The transfer requests handle the actual transfer
  def transfer_aliquots
    TransferRequest.create!(asset: asset, target_asset: target_asset, outer_request: self)
  end
end
