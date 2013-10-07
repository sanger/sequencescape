class CherrypickForPulldownRequest < TransferRequest


  def perform_transfer_of_contents
    on_started # Ensures we set the study/project
  end
  private :perform_transfer_of_contents

  after_create :build_stock_well_links

  def build_stock_well_links
    stock_wells = asset.plate.try(:plate_purpose).try(:can_be_considered_a_stock_plate?) ? [asset] : asset.stock_wells
    target_asset.stock_wells.attach!(stock_wells)
  end
  private :build_stock_well_links

end
