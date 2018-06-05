
class IlluminaHtp::TransferablePlatePurpose < IlluminaHtp::FinalPlatePurpose
  include PlatePurpose::RequestAttachment
  include PlatePurpose::WorksOnLibraryRequests

  self.connect_on = 'qc_complete'
  self.connect_downstream = true

  def source_wells_for(wells)
    Well.in_column_major_order.stock_wells_for(wells)
  end
end
