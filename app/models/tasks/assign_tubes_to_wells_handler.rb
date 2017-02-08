# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015 Genome Research Ltd.

module Tasks::AssignTubesToWellsHandler
  MAX_SMRT_CELLS_PER_WELL = 7

  def render_assign_tubes_to_wells_task(task, params)
    available_tubes = uniq_assets_from_requests
    @available_tubes_options = [['', nil]] | available_tubes.map { |t| [t.name, t.id] }

    @tubes = calculate_number_of_wells_library_needs_to_use(task, params)
  end

  def do_assign_tubes_to_wells_task(task, params)
    tubes_to_well_positions = tubes_to_wells(params)
    library_tubes = uniq_assets_from_requests

    requests = task.find_batch_requests(params[:batch_id])

    ActiveRecord::Base.transaction do
      plate = Plate.create!(barcode: PlateBarcode.create.barcode)

      library_tubes.each do |library_tube|
        library_well_positions = all_well_positions_for_library_tube(tubes_to_well_positions, library_tube)
        requests.select { |request| request.asset == library_tube }.each_slice(MAX_SMRT_CELLS_PER_WELL) do |requests_for_library|
          well_position = library_well_positions.shift
          raise 'Not enough well positions to satisfy requests' if well_position.nil?

          well = find_target_asset_from_requests(requests_for_library)
          well.update_attributes!(map: Map.find_by(description: well_position, asset_size: 96), plate: plate)
          assign_requests_to_well(requests_for_library, well)
        end
      end
    end

    true
  end

  # Plate is an option parameter for a target plate. Used in multiplexed
  # cherrypicking. In its absence a plate is created
  def do_assign_requests_to_multiplexed_wells_task(task, params, plate = nil)
    plate ||= find_or_create_plate(task.purpose)

    well_hash = Hash[plate.wells.located_at(params[:request_locations].values.uniq).map { |w| [w.map_description, w] }]

    problem_wells = wells_with_duplicates(params)

    if problem_wells.present?
      flash[:error] = "Duplicate tags in #{problem_wells.join(',')}"
      return false
    end

    incompatible_wells = find_incompatible_wells(params)

    if incompatible_wells.present?
      flash[:error] = "Incompatible requests in #{incompatible_wells.join(',')}"
      return false
    end

    @batch.requests.each do |request|
      target_well = params[:request_locations][request.id.to_s]
      request.target_asset = well_hash[target_well]
      request.save!
    end
    true
  end

  def do_assign_pick_volume_task(_task, params)
    @batch.requests.each do |r|
      next if r.target_asset.nil?
      r.target_asset.set_picked_volume(params[:micro_litre_volume_required].to_i)
    end
    true
  end

  # Identifies and array of well map descriptions that contain duplicate tags
  # First filters out any equivalent aliquots. (ie. same sample, tag, library_type, etc.)
  def wells_with_duplicates(params)
    invalid_wells = []
    @batch.requests.group_by { |request| params[:request_locations][request.id.to_s] }.each do |well, requests|
      all_aliquots = requests.map { |r| r.asset.aliquots }.flatten
      # Push each aliquot onto an array as long as it doesn't match an aliquot already on the array
      unique_aliquots = all_aliquots.each_with_object([]) do |candidate, selected_aliquots|
        selected_aliquots << candidate unless selected_aliquots.any? { |existing_aliquot| existing_aliquot.equivalent?(candidate) }
      end
      # uniq! returns any duplicates, or nil if there are none
      next if unique_aliquots.map(&:tag_id).uniq!.nil?
      invalid_wells << well
    end
    invalid_wells
  end
  private :wells_with_duplicates

  def find_incompatible_wells(params)
    invalid_wells = []
    @batch.requests.group_by { |request| params[:request_locations][request.id.to_s] }.each do |well, requests|
      next if requests.map { |r| r.shared_attributes }.uniq.count <= 1
      invalid_wells << well
    end
    invalid_wells
  end
  private :find_incompatible_wells

  def find_or_create_plate(purpose)
    first_request = @batch.requests.first
    first_request.target_asset.try(:plate) || purpose.create!
  end

  def find_target_asset_from_requests(requests)
    requests.map { |request| request.target_asset }.select { |asset| !asset.nil? }.first
  end

  def assign_requests_to_well(requests, well)
    requests.each do |request|
      request.update_attributes!(target_asset: well)
    end
  end

  def all_well_positions_for_library_tube(tubes_to_well_positions, library_tube)
    tubes_to_well_positions.select { |tube_to_well| tube_to_well[0] == library_tube }.map { |tube_to_well| tube_to_well[1] }
  end

  def tubes_to_wells(params)
    tubes_to_well_positions = []
    params[:well].each do |well_position, asset_id|
      next if asset_id.blank?
      tubes_to_well_positions << [PacBioLibraryTube.find(asset_id.to_i), well_position]
    end

    tubes_to_well_positions
  end

  def assets_from_requests
    @afr ||= @batch.requests.map { |request| request.asset }
  end

  def uniq_assets_from_requests
    @uafr ||= assets_from_requests.uniq
  end

  def assets_from_requests_sorted_by_id
    @asbi ||= assets_from_requests.sort_by(&:id)
  end

  def calculate_number_of_wells_library_needs_to_use(_task, _params)
    tubes_for_wells = []
    assets = assets_from_requests_sorted_by_id
    physical_library_tubes = uniq_assets_from_requests

    physical_library_tubes.each do |library_tube|
      number_of_wells = ((assets.select { |asset| asset == library_tube }.size.to_f) / MAX_SMRT_CELLS_PER_WELL).ceil
      next if number_of_wells == 0
      1.upto(number_of_wells) do
        tubes_for_wells << library_tube
      end
    end

    tubes_for_wells
  end
end
