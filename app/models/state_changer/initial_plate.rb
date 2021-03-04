# frozen_string_literal: true

module StateChanger
  # Customized order lookup behaviour for PlatePurpose::InitialPurpose
  # Almost certainly redundant, but migrating it while I refactor.
  # See PlatePurpose::InitialPurpose for deprecation details
  class InitialPlate < StandardPlate
    private

    def pending_orders
      orders = Set.new
      each_well_and_its_library_request do |order_id|
        orders << order_id
      end
      orders
    end

    def each_well_and_its_library_request
      well_to_stock_id = Hash[labware.stock_wells.map { |well, stock_wells| [well.id, stock_wells.first.id] }]
      requests = Request::LibraryCreation.for_asset_id(well_to_stock_id.values).include_request_metadata.group_by(&:asset_id)

      labware.wells.includes({ aliquots: :library }, :requests_as_target).find_each do |well|
        next if well.aliquots.empty?

        stock_id       = well_to_stock_id[well.id] or raise "No stock well for #{well.id.inspect} (#{well_to_stock_id.inspect})"
        stock_requests = requests[stock_id]        or raise "No requests for stock well #{stock_id.inspect} (#{requests.inspect})"
        stock_request  = stock_requests.detect { |request| request.submission_id == well.submission_ids.first }

        stock_request or raise "No requests for stock well #{stock_id.inspect} with matching submission (#{requests.inspect})"
        yield(stock_request.order_id) if request.pending?
      end
    end
  end
end
