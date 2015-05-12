#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
class IlluminaHtp::TransferablePlatePurpose < IlluminaHtp::FinalPlatePurpose
  include PlatePurpose::Library
  include PlatePurpose::RequestAttachment

  write_inheritable_attribute :connect_on, 'qc_complete'
  write_inheritable_attribute :connect_downstream, true
  write_inheritable_attribute :connected_class, IlluminaHtp::Requests::SharedLibraryPrep

  def source_wells_for(wells)
    Well.in_column_major_order.stock_wells_for(wells)
  end

  def each_well_and_its_library_request(plate, &block)
    well_to_stock_id = Hash[plate.wells.map { |well| [well.id, well.stock_wells.first.try(:id)] }.reject { |_,v| v.nil? }]
    requests         = Request::LibraryCreation.for_asset_id(well_to_stock_id.values).include_request_metadata.group_by(&:asset_id)
    plate.wells.all(:include => { :aliquots => :library }).each do |well|
      next if well.aliquots.empty?
      stock_id       = well_to_stock_id[well.id] or raise "No stock well for #{well.id.inspect} (#{well_to_stock_id.inspect})"
      stock_requests = requests[stock_id]        or raise "No requests for stock well #{stock_id.inspect} (#{requests.inspect})"
      yield(well, stock_requests.first)
    end
  end
  private :each_well_and_its_library_request

end
