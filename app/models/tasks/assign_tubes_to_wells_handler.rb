# frozen_string_literal: true
# Handles the behaviour of {AssignTubesToMultiplexedWellsTask}
# and included in {WorkflowsController}
# Also used by {MultiplexedCherrypickingTask}
# {include:AssignTubesToMultiplexedWellsTask}
module Tasks::AssignTubesToWellsHandler
  # Plate is an option parameter for a target plate. Used in multiplexed
  # cherrypicking. In its absence a plate is created
  # rubocop:todo Metrics/MethodLength
  def do_assign_requests_to_multiplexed_wells_task(task, params, plate = nil) # rubocop:todo Metrics/AbcSize
    plate ||= find_or_create_plate(task.purpose)

    well_hash = plate.wells.located_at(params[:request_locations].values.uniq).index_by(&:map_description)

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

  # rubocop:enable Metrics/MethodLength

  def do_assign_pick_volume_task(_task, params)
    @batch.requests.each do |r|
      next if r.target_asset.nil?

      r.target_asset.set_picked_volume(params[:micro_litre_volume_required].to_i)
    end
    true
  end

  # Identifies and array of well map descriptions that contain duplicate tags
  # First filters out any equivalent aliquots. (ie. same sample, tag, library_type, etc.)
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def wells_with_duplicates(params) # rubocop:todo Metrics/CyclomaticComplexity
    invalid_wells = []
    @batch
      .requests
      .group_by { |request| params[:request_locations][request.id.to_s] }
      .each do |well, requests|
        all_aliquots = requests.reduce([]) { |array, r| array.concat(r.asset.aliquots) }

        # Push each aliquot onto an array as long as it doesn't match an aliquot already on the array
        unique_aliquots =
          all_aliquots.each_with_object([]) do |candidate, selected_aliquots|
            unless selected_aliquots.any? { |existing_aliquot| existing_aliquot.equivalent?(candidate) }
              selected_aliquots << candidate
            end
          end

        # uniq! returns any duplicates, or nil if there are none
        next if unique_aliquots.map(&:tag_id).uniq!.nil?

        invalid_wells << well
      end
    invalid_wells
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
  private :wells_with_duplicates

  def find_incompatible_wells(params)
    invalid_wells = []
    @batch
      .requests
      .group_by { |request| params[:request_locations][request.id.to_s] }
      .each do |well, requests|
        next if requests.map(&:shared_attributes).uniq.count <= 1

        invalid_wells << well
      end
    invalid_wells
  end
  private :find_incompatible_wells

  def find_or_create_plate(purpose)
    first_request = @batch.requests.first
    first_request.target_asset.try(:plate) || purpose.create!
  end
end
