# Every request "moving" an asset from somewhere to somewhere else 
# without really transforming it (chemically) as, cherrypicking, pooling, spreading on the floor etc
class TransferRequest < Request
  # Upon starting a transfer request, we need to transfer the contents of the source asset to the
  # destination asset.  The contents are not only the samples, but also any tags that have been bound
  # through asset links.
  before_save(:perform_transfer_of_contents, :if => :started?)

  def perform_transfer_of_contents
    transfer_samples
    transfer_tags
  end
  private :perform_transfer_of_contents

  def transfer_samples
    # TODO: Transfers can go from many sources to one destination so multiple samples are needed
    target_asset.update_attributes!(:sample => asset.sample)
  end
  private :transfer_samples

  # Transferring the tags means creating a new tag instance based on the original.
  def transfer_tags
    asset.parents.each do |potential_tag|
      potential_tag.tag.tag!(target_asset) if potential_tag.is_a?(TagInstance)
    end
  end
  private :transfer_tags
end
