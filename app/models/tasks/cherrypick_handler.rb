# frozen_string_literal: true

# Handles the behaviour of {CherrypickTask} and included in {WorkflowsController}
# {include:CherrypickTask}
module Tasks::CherrypickHandler
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickHelpers
    end
  end

  def render_cherrypick_task(_task, params)
    if flash[:error].present?
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return
    end

    plate_template = nil
    plate_template = PlateTemplate.find(params[:plate_template]['0'].to_i) if params[:plate_template].present?
    if plate_template.nil?
      flash[:error] = 'Please select a template'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return
    end

    setup_input_params_for_pass_through

    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @requests = @batch.ordered_requests

    @plate = nil
    @plate_barcode = params[:existing_plate]
    @fluidigm_plate = params[:fluidigm_plate]

    if @plate_barcode.present?
      @plate = Plate.find_from_barcode(@plate_barcode)
      if @plate.nil?
        flash[:error] = 'Invalid plate barcode'
        redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
        return
      end
    elsif @fluidigm_plate.present?
      if @fluidigm_plate.size > 10
        flash[:error] = 'Invalid fluidigm barcode'
        redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
        return
      end
      @plate = Plate.find_from_barcode(@fluidigm_barcode)
    end

    @plate_purpose = PlatePurpose.find(params[:plate_purpose_id])
    flash.now[:warning] = I18n.t('cherrypick.picking_by_row') if @plate_purpose.cherrypick_in_rows?

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @map_info = if @spreadsheet_layout
                  @spreadsheet_layout
                elsif @plate.present?
                  @task.pick_onto_partial_plate(@requests, plate_template, @robot, @plate)
                else
                  @task.pick_new_plate(@requests, plate_template, @robot, @plate_purpose)
                end
    @plates = @map_info[0]
    @source_plate_ids = @map_info[1]

    @plate_cols = @plate.try(:width) || @plate_purpose.plate_width
    @plate_rows = @plate.try(:height) || @plate_purpose.plate_height
  end

  def setup_input_params_for_pass_through
    @robot_id = params[:robot_id]
    @robot = Robot.find(@robot_id)
    @plate_type = params[:plate_type]
    if params[:nano_grams_per_micro_litre]
      @nano_grams_per_micro_litre_volume_required = params[:nano_grams_per_micro_litre][:volume_required]
      @nano_grams_per_micro_litre_concentration_required = params[:nano_grams_per_micro_litre][:concentration_required]
      @nano_grams_per_micro_litre_robot_minimum_picking_volume = params[:nano_grams_per_micro_litre][:robot_minimum_picking_volume]
    end
    if params[:nano_grams]
      @nano_grams_minimum_volume = params[:nano_grams][:minimum_volume]
      @nano_grams_maximum_volume = params[:nano_grams][:maximum_volume]
      @nano_grams_total_nano_grams = params[:nano_grams][:total_nano_grams]
      @nano_grams_robot_minimum_picking_volume = params[:nano_grams][:robot_minimum_picking_volume]
    end
    @micro_litre_volume_required = params[:micro_litre][:volume_required] if params[:micro_litre]
    @cherrypick_action = params[:cherrypick][:action]
    @plate_purpose_id = params[:plate_purpose_id]
    @fluidigm_barcode = params[:fluidigm_plate]
  end

  def do_cherrypick_task(_task, params) # rubocop:todo Metrics/CyclomaticComplexity
    plates = params[:plate]
    size = params[:plate_size]
    plate_type = params[:plate_type]

    ActiveRecord::Base.transaction do # rubocop:todo Metrics/BlockLength
      # Determine if there is a standard plate to use.
      partial_plate = nil
      plate_barcode = params[:plate_barcode]
      fluidigm_plate = params[:fluidigm_plate]
      partial_plate = Plate.find_from_barcode(fluidigm_plate.presence || plate_barcode)
      raise(Cherrypick::Error, "No plate with barcode #{plate_barcode}") if partial_plate.nil? && plate_barcode.present?

      # Ensure that we have a plate purpose for any plates we are creating
      plate_purpose = PlatePurpose.find(params[:plate_purpose_id])
      asset_shape_id = plate_purpose.asset_shape_id

      # Configure the cherrypicking action based on the parameters
      cherrypicker =
        case params[:cherrypick_action]
        when 'nano_grams_per_micro_litre' then create_nano_grams_per_micro_litre_picker(params[:nano_grams_per_micro_litre])
        when 'nano_grams'                 then create_nano_grams_picker(params[:nano_grams])
        when 'micro_litre'                then create_micro_litre_picker(params[:micro_litre])
        else raise StandardError, "Invalid cherrypicking type #{params[:cherrypick_action]}"
        end

      # We can preload the well locations so that we can do efficient lookup later.
      well_locations = Map.where_plate_size(partial_plate.try(:size) || size).where_plate_shape(partial_plate.try(:asset_shape) || asset_shape_id).in_row_major_order.index_by(&:description)

      # All of the requests we're going to be using should be part of the batch.  If they are not
      # then we have an error, so we can pre-map them for quick lookup.  We're going to pre-cache a
      # whole load of wells so that they can be retrieved quickly and easily.
      wells = Well.includes(:well_attribute).find(@batch.requests.map(&:target_asset_id)).index_by(&:id)
      request_and_well = Hash[@batch.requests.includes(:request_metadata).map { |r| [r.id.to_i, [r, wells[r.target_asset_id]]] }]
      used_requests = []
      plates_and_wells = Hash.new { |h, k| h[k] = [] }
      plate_and_requests = Hash.new { |h, k| h[k] = [] }

      # If we overflow the plate we create a new one, even if we subsequently clear the fields.
      plates_with_samples = plates.reject { |_pid, rows| rows.values.map(&:values).flatten.all?(&:empty?) }

      raise Cherrypick::Error, 'Sorry, You cannot pick to multiple fluidigm plates in one batch.' if fluidigm_plate.present? && plates_with_samples.to_h.size > 1

      plates_with_samples.each do |_id, plate_params|
        # The first time round this loop we'll either have a plate, from the partial_plate, or we'll
        # be needing to create a new one.
        plate = partial_plate
        if plate.nil?
          barcode_number = PlateBarcode.create.barcode
          barcode = { prefix: plate_purpose.prefix, number: barcode_number }
          plate   = plate_purpose.create!(:do_not_create_wells, name: "Cherrypicked #{barcode_number}", size: size, sanger_barcode: barcode) do |new_plate|
            new_plate.fluidigm_barcode = fluidigm_plate if fluidigm_plate.present?
          end
        end

        # Set the plate type, regardless of what it was.  This may change the standard plate.
        plate.plate_type = plate_type unless plate_type.nil?
        plate.save!

        plate_params.each do |row, row_params|
          row = row.to_i
          row_params.each do |col, request_id|
            next if request_id.blank?

            request, well = request_and_well[request_id.gsub('well_', '').to_i] || raise(ActiveRecord::RecordNotFound, "Cannot find request #{request_id.inspect}")

            # NOTE: Performance enhancement here
            # This collects the wells together for the plate they should be on, and modifies
            # the values in the well data.  It *does not* save either of these, which means that
            # SELECT & INSERT/UPDATE are not interleaved, which affects the cache
            well.map = well_locations[plate.asset_shape.location_from_row_and_column(row, col.to_i + 1, plate.size)]
            cherrypicker.call(well, request)
            plates_and_wells[plate] << well
            plate_and_requests[plate] << request
            used_requests << request
          end
        end

        # At this point we can consider ourselves finished with the partial plate
        partial_plate = nil
      end

      # Attach the wells into their plate for maximum efficiency.
      plates_and_wells.each do |plate, plate_wells|
        plate_wells.each do |w|
          w.well_attribute.save!
          w.save!
        end
        plate.wells << plate_wells
      end

      links = plate_and_requests.flat_map do |target_plate, requests|
        Plate.with_requests(requests).map do |source_plate|
          [source_plate.id, target_plate.id]
        end
      end.uniq

      @batch.lab_events.create(description: 'Cherrypick Layout Set', message: 'Layout set', user_id: current_user.id,
                               descriptors: {
                                 'robot_id' => params[:robot_id]
                               })

      AssetLink::BuilderJob.create(links)

      # Now pass each of the requests we used and ditch any there weren't back into the inbox.
      used_requests.map(&:pass!)
      (@batch.requests - used_requests).each(&:recycle_from_batch!)
    end
  end
end
