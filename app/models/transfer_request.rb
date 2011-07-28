# Every request "moving" an asset from somewhere to somewhere else without really transforming it
# (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  # Ensure that the source and the target assets are not the same, otherwise bad things will happen!
  validate do |record|
    if record.asset.present? and record.asset == record.target_asset
      record.errors.add(:asset, 'cannot be the same as the target')
      record.errors.add(:target_asset, 'cannot be the same as the source')
    end
  end

  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:clone) unless asset.failed? or asset.cancelled?
  end
  private :perform_transfer_of_contents

  # TODO: Now that callbacks are in place we probably should do the transfer on passing a request.
  def on_started
    # Override the default behaviour to not do the transfer
  end
end
