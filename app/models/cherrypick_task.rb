# frozen_string_literal: true

# A {Task} used in {CherrypickPipeline cherrypick pipelines}
# Performs the main bulk of cherrypick action. Although a lot of the options
# on this page are presented as part of the previous step, and get persisted on this
# page as hidden fields.
# This page shows a drag-drop plate layout which lets users set-up the way the plate will be picked.
# The target asset of each request will have its plate and map set accordingly.
# Well attributes are set to track picking volumes
#
# @see PlateTemplateTask for previous step
# @see Tasks::CherrypickHandler for behaviour included in the {WorkflowsController}
class CherrypickTask < Task
  EMPTY_WELL          = [0, 'Empty', ''].freeze
  TEMPLATE_EMPTY_WELL = [0, '---', ''].freeze

  # A cherrypick batch may contain multiple destination plates. In this case the control wells
  # should be located at different locations on each destination. The positions on the first
  # plate in a batch are determined randomly, and then the locations are advanced by
  # BETWEEN_PLATE_OFFSET for each subsequent plate. This is done to avoid the risk of
  # subsequent plates having the same negative control location, which would reduce the ability to
  # detect plate swaps.
  # WARNING! These needs to be a prime number (which isn't also a factor of the available well size)
  # to avoid re-using wells prematurely. These offsets are prioritised in order
  BETWEEN_PLATE_OFFSETS = [53, 59].freeze

  #
  # Returns a list with the destination positions for the control wells distributed randomly
  # using batch_id as seed and num_plate to increase position with plates in same batch.
  # @note wells_to_leave_free was originally hardcoded for 96 well plates at 24, in order to avoid
  # control wells being missed in cDNA quant QC. This requirement was removed in
  # https://github.com/sanger/sequencescape/issues/2967 however I've avoided stripping out the behaviour
  # completely in case controls are used in other pipelines.
  #
  # @param batch_id [Integer] The id of the batch, used to generate a starting position
  # @param num_plate [Integer] The plate number within the batch
  # @param total_wells [Integer] The total number of wells on the plate
  # @param num_control_wells [Integer] The number of control wells to lay out
  # @param wells_to_leave_free [Integer] The number of wells to leave free at the front of the plate
  #
  # @return [Array<Integer>] The indexes of the control well positions
  #
  def control_positions(batch_id, num_plate, total_wells, num_control_wells, wells_to_leave_free: 0)
    # total_available_positions = total_wells - wells_to_leave_free

    # raise StandardError, 'More controls than free wells' if num_control_wells > total_available_positions

    # available_positions = (wells_to_leave_free...total_wells).to_a
    # # If num plate is equal to the available positions, the cycle is going to be repeated.
    # # To avoid it, every num_plate=available_positions we start a new cycle with a new seed.
    # seed = batch_id * ((num_plate / available_positions.length) + 1)
    # initial_positions = random_elements_from_list(available_positions, num_control_wells, seed)
    # control_positions_for_plate(num_plate, initial_positions, available_positions)
    CherrypickTask::ControlLocator.new(
      batch_id: batch_id,
      total_wells: total_wells,
      num_control_wells: num_control_wells,
      wells_to_leave_free: wells_to_leave_free
    ).control_positions(num_plate)
  end

  def pick_new_plate(requests, template, robot, plate_purpose, auto_add_control_plate = nil, workflow_controller = nil)
    target_type = PickTarget.for(plate_purpose)
    perform_pick(requests, robot, auto_add_control_plate, workflow_controller) do
      target_type.new(template, plate_purpose.try(:asset_shape))
    end
  end

  def pick_onto_partial_plate(requests, template, robot, partial_plate, auto_add_control_plate = nil, workflow_controller = nil)
    purpose = partial_plate.plate_purpose
    target_type = PickTarget.for(purpose)

    perform_pick(requests, robot, auto_add_control_plate, workflow_controller) do
      target_type.new(template, purpose.try(:asset_shape), partial_plate).tap do
        partial_plate = nil # Ensure that subsequent calls have no partial plate
      end
    end
  end

  def perform_pick(requests, robot, auto_add_control_plate, workflow_controller)
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    destination_plates = []
    current_destination_plate = yield # instance of ByRow, ByColumn or ByInterlacedColumn
    source_plates = Set.new
    plates_array = build_plate_wells_from_requests(requests, workflow_controller)

    # Initial settings needed for control requests addition
    if auto_add_control_plate
      num_plate = 0
      batch = requests.first.batch
      control_assets = auto_add_control_plate.wells.joins(:samples)
      control_posns = control_positions(batch.id, num_plate, current_destination_plate.size, control_assets.count)

      # If is an incomplete plate, or a plate with a template applied, copy all the controls missing into the
      # beginning of the plate
      current_destination_plate.add_any_initial_control_requests(control_posns, batch, control_assets)
    end

    push_completed_plate = lambda do |idx|
      destination_plates << current_destination_plate.completed_view
      current_destination_plate = yield # reset to start picking to a fresh one
      if auto_add_control_plate && (idx < (plates_array.length - 1))
        # when we start a new plate we rebuild the list of positions where the requests should be placed
        num_plate += 1
        control_posns = control_positions(batch.id, num_plate, current_destination_plate.size, control_assets.count)
        current_destination_plate.add_any_initial_control_requests(control_posns, batch, control_assets)
      end
    end

    plates_array.each_with_index do |list, idx|
      request_id, plate_barcode, well_location = list
      source_plates << plate_barcode
      current_destination_plate.push_with_controls(request_id, plate_barcode, well_location,
                                                   control_posns, batch, control_assets)
      push_completed_plate.call(idx) if current_destination_plate.full?
    end
    # If there are any remaining control requests, we'll add all of them at the end of the last plate
    unless current_destination_plate.empty?
      current_destination_plate.add_remaining_control_requests(control_posns, batch, control_assets) if auto_add_control_plate
    end

    # Ensure that a non-empty plate is stored
    push_completed_plate.call(plates_array.length) unless current_destination_plate.empty?

    [destination_plates, source_plates]
  end
  private :perform_pick

  def partial
    'cherrypick_batches'
  end

  def render_task(workflow_controller, params)
    super
    workflow_controller.render_cherrypick_task(self, params)
  end

  def do_task(workflow_controller, params)
    workflow_controller.do_cherrypick_task(self, params)
  rescue Cherrypick::Error => e
    workflow_controller.send(:flash)[:error] = e.message
    false
  end

  # returns array [ [ request id, source plate barcode, source coordinate ] ]
  def build_plate_wells_from_requests(requests, workflow_controller = nil)
    loaded_requests = Request.where(requests: { id: requests })
                             .includes(asset: [{ plate: :barcodes }, :map])

    source_plate_barcodes = loaded_requests.map { |request| request.asset.plate.human_barcode }.uniq

    begin
      # retrieve Labwhere locations for all source_plate_barcodes, in form { 'DN1234' => 'Sanger / Room 1 - Shelf 2' }
      labwhere_response = Labware.labwhere_locations(source_plate_barcodes)
      barcodes_sorted_by_location = labwhere_response.sort_by { |_k, v| v }.to_h.keys
    rescue LabWhereClient::LabwhereException => e
      message = "Labware locations are unavailable (#{e.message}). Wells are sorted by plate creation order."
      workflow_controller.send(:flash)[:error] = message unless workflow_controller.nil?

      barcodes_sorted_by_location = source_plate_barcodes
    end

    # sort by location in lab, followed by plate id, followed by well coordinate on plate
    sorted_requests = loaded_requests.sort_by do |request|
      [barcodes_sorted_by_location.index(request.asset.plate.human_barcode), request.asset.plate.id, request.asset.map.column_order]
    end

    sorted_requests.map do |request|
      [request.id, request.asset.plate.human_barcode, request.asset.map_description]
    end
  end
end
