module Tasks::AssignTubesToWellsHandler
  MAX_SMRT_CELLS_PER_WELL = 7

  def render_assign_tubes_to_wells_task(task, params)
    available_tubes = uniq_assets_from_requests(task, params)
    @available_tubes_options = [['',nil]] | available_tubes.map{ |t| ["Tube #{t.barcode}", t.id] }

    @tubes = calculate_number_of_wells_library_needs_to_use(task, params)
  end

  def do_assign_tubes_to_wells_task(task, params)
    tubes_to_well_positions = tubes_to_wells(params)
    library_tubes = uniq_assets_from_requests(task, params)

    requests = task.find_batch_requests(params[:batch_id])

    ActiveRecord::Base.transaction do
      plate = Plate.create!(:barcode => PlateBarcode.create.barcode)

      library_tubes.each do |library_tube|
        library_well_positions = all_well_positions_for_library_tube(tubes_to_well_positions, library_tube)
        requests.select{ |request| request.asset == library_tube }.each_slice(MAX_SMRT_CELLS_PER_WELL) do |requests_for_library|
          well_position = library_well_positions.shift
          raise "Not enough well positions to satisfy requests" if well_position.nil?

          well = find_target_asset_from_requests(requests_for_library)
          well.update_attributes!(:map => Map.find_by_description_and_asset_size(well_position, 96), :plate => plate)
          assign_requests_to_well(requests_for_library, well)

        end
      end
    end

    true
  end

  def find_target_asset_from_requests(requests)
    requests.map{ |request| request.target_asset }.select{ |asset| ! asset.nil? }.first
  end

  def assign_requests_to_well(requests,well)
    requests.each do |request|
      request.update_attributes!(:target_asset => well)
    end
  end

  def all_well_positions_for_library_tube(tubes_to_well_positions, library_tube)
    tubes_to_well_positions.select{ |tube_to_well| tube_to_well[0] == library_tube }.map{ |tube_to_well| tube_to_well[1] }
  end

  def tubes_to_wells(params)
    tubes_to_well_positions = []
    params[:well].each do |well_position, asset_id|
      next if asset_id.blank?
      tubes_to_well_positions << [PacBioLibraryTube.find(asset_id.to_i), well_position]
    end

    tubes_to_well_positions
  end

  def assets_from_requests(task, params)
    task.find_batch_requests(params[:batch_id]).map{ |request| request.asset }
  end

  def uniq_assets_from_requests(task, params)
    assets_from_requests(task, params).uniq
  end

  def assets_from_requests_sorted_by_id(task, params)
    assets_from_requests(task, params).sort{ |a,b| a.id <=> b.id }
  end

  def calculate_number_of_wells_library_needs_to_use(task, params)
    tubes_for_wells = []
    assets = assets_from_requests_sorted_by_id(task, params)
    physical_library_tubes = uniq_assets_from_requests(task, params)

    physical_library_tubes.each do |library_tube|
      number_of_wells = ((assets.select{ |asset| asset == library_tube }.size.to_f) / MAX_SMRT_CELLS_PER_WELL).ceil
      next if number_of_wells == 0
      1.upto(number_of_wells) do
        tubes_for_wells << library_tube
      end
    end

    tubes_for_wells
  end
end
