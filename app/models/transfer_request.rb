# Every request "moving" an asset from somewhere to somewhere else 
# without really transforming it (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  after_create(:perform_transfer_of_contents)

  def perform_transfer_of_contents
    target_asset.aliquots << asset.aliquots.map(&:clone)
  end
  private :perform_transfer_of_contents
end
