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
class CherrypickTask < Task # rubocop:todo Metrics/ClassLength
  EMPTY_WELL = [0, 'Empty', ''].freeze
  TEMPLATE_EMPTY_WELL = [0, '---', ''].freeze
  DEFAULT_WELLS_TO_LEAVE_FREE = Rails.application.config.plate_default_control_wells_to_leave_free

  #
  # Returns a {CherrypickTask::ControlLocator} which can generate control locations for plates
  # in a batch. It responds to #control_positions which takes a plate number as an argument
  #
  # @return [CherrypickTask::ControlLocator] A generator of control locations
  #
  def new_control_locator(batch_id, total_wells, num_control_wells, wells_to_leave_free: DEFAULT_WELLS_TO_LEAVE_FREE)
    CherrypickTask::ControlLocator.new(
      batch_id:,
      total_wells:,
      num_control_wells:,
      wells_to_leave_free:
    )
  end

  #
  # Cherrypick tasks are directly coupled to the previous task, due to the awkward
  # way in which the WorkflowsController operates. See issues#2831 for aims to help improve some of this
  #
  # @return [false,'Can only be accessed via the previous step'>] Array indicating this action can't be linked
  #
  def can_link_directly?
    [false, 'Can only be accessed via the previous step']
  end

  # rubocop:todo Metrics/ParameterLists
  def pick_new_plate(requests, template, robot, plate_purpose, control_source_plate = nil, workflow_controller = nil)
    target_type = PickTarget.for(plate_purpose)
    perform_pick(requests, robot, control_source_plate, workflow_controller) do
      target_type.new(template, plate_purpose.try(:asset_shape))
    end
  end

  def pick_onto_partial_plate(
    requests,
    template,
    robot,
    partial_plate,
    control_source_plate = nil,
    workflow_controller = nil
  )
    purpose = partial_plate.plate_purpose
    target_type = PickTarget.for(purpose)

    perform_pick(requests, robot, control_source_plate, workflow_controller) do
      target_type
        .new(template, purpose.try(:asset_shape), partial_plate)
        .tap do
          partial_plate = nil # Ensure that subsequent calls have no partial plate
        end
    end
  end

  # rubocop:enable Metrics/ParameterLists

  # rubocop:todo Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
  def perform_pick(requests, robot, control_source_plate, workflow_controller) # rubocop:todo Metrics/AbcSize
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    destination_plates = []
    current_destination_plate = yield # instance of ByRow, ByColumn or ByInterlacedColumn
    source_plates = Set.new
    plates_array = build_plate_wells_from_requests(requests, workflow_controller)

    # Initial settings needed for control requests addition
    if control_source_plate
      num_plate = 0
      batch = requests.first.batch
      control_assets = control_source_plate.wells.joins(:samples)
      control_locator = new_control_locator(batch.id, current_destination_plate.size, control_assets.count)
      control_posns = control_locator.control_positions(num_plate)

      # If is an incomplete plate, or a plate with a template applied, copy all the controls missing into the
      # beginning of the plate
      current_destination_plate.add_any_initial_control_requests(control_posns, batch, control_assets)
    end

    push_completed_plate =
      lambda do |idx|
        destination_plates << current_destination_plate.completed_view
        current_destination_plate = yield # reset to start picking to a fresh one
        if control_source_plate && (idx < (plates_array.length - 1))
          # when we start a new plate we rebuild the list of positions where the requests should be placed
          num_plate += 1
          control_posns = control_locator.control_positions(num_plate)
          current_destination_plate.add_any_initial_control_requests(control_posns, batch, control_assets)
        end
      end

    plates_array.each_with_index do |list, idx|
      request_id, plate_barcode, well_location = list
      source_plates << plate_barcode
      current_destination_plate.push_with_controls(
        request_id,
        plate_barcode,
        well_location,
        control_posns,
        batch,
        control_assets
      )
      push_completed_plate.call(idx) if current_destination_plate.full?
    end

    # If our plate isn't empty we'll add any controls, and push it to the array
    unless current_destination_plate.empty?
      # If there are any remaining control requests, we'll add all of them at the end of the last plate
      if control_source_plate
        current_destination_plate.add_remaining_control_requests(control_posns, batch, control_assets)
      end

      # Ensure that a non-empty plate is stored
      push_completed_plate.call(plates_array.length)
    end

    [destination_plates, source_plates]
  end

  # rubocop:enable Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  private :perform_pick

  def partial
    'cherrypick_batches'
  end

  def render_task(workflow_controller, params, _user)
    super
    workflow_controller.render_cherrypick_task(self, params)
  end

  def do_task(workflow_controller, params, _user)
    workflow_controller.do_cherrypick_task(self, params)
  rescue Cherrypick::Error => e
    workflow_controller.send(:flash)[:error] = e.message
    [false, e.message]
  end

  # returns array [ [ request id, source plate barcode, source coordinate ] ]
  # rubocop:todo Metrics/MethodLength
  def build_plate_wells_from_requests(requests, workflow_controller = nil) # rubocop:todo Metrics/AbcSize
    loaded_requests = Request.where(requests: { id: requests }).includes(asset: [{ plate: :barcodes }, :map])

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
    sorted_requests =
      loaded_requests.sort_by do |request|
        [
          barcodes_sorted_by_location.index(request.asset.plate.human_barcode),
          request.asset.plate.id,
          request.asset.map.column_order
        ]
      end

    sorted_requests.map { |request| [request.id, request.asset.plate.human_barcode, request.asset.map_description] }
  end
  # rubocop:enable Metrics/MethodLength
end
