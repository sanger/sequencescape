module Tasks::CherrypickHandler
  def self.included(base)
    base.class_eval do
      include Cherrypick::Task::PickHelpers
    end
  end

  def render_cherrypick_task(task, params)
    unless flash[:error].blank?
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (@stage -1).to_s
      return
    end

    plate_template = nil
    unless params[:plate_template].blank?
      plate_template = PlateTemplate.find(params[:plate_template]["0"].to_i)
    end
    if plate_template.nil?
      flash[:error] = "Please select a template"
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (@stage -1).to_s
      return
    end

    setup_input_params_for_pass_through

    @batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
    @requests = @batch.ordered_requests

    @plate_barcode = params[:existing_plate]
    @plate = nil
    unless @plate_barcode.blank?
      plate_barcode_id = @plate_barcode.to_i
      plate_barcode_id = Barcode.number_to_human(@plate_barcode.to_i) if plate_barcode_id > 11
      @plate = Plate.find_by_barcode(plate_barcode_id.to_s)
      if @plate.nil?
        flash[:error] = "Invalid plate barcode"
        redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (@stage -1).to_s
        return
      end

      action_flash[:warning] = I18n.t("cherrypick.picking_by_row") if @plate.plate_purpose.cherrypick_in_rows?
    end

    @plate_purpose = PlatePurpose.find(params[:plate_purpose_id])
    action_flash[:warning] = I18n.t("cherrypick.picking_by_row") if @plate_purpose.cherrypick_in_rows?

    unless @batch.started? || @batch.failed?
      @batch.start!(current_user)
    end

    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
    if @spreadsheet_layout
      @map_info = @spreadsheet_layout
    elsif @plate.present?
      @map_info = @task.pick_onto_partial_plate(@requests,plate_template,@robot,@batch,@plate)
    else
      @map_info = @task.pick_new_plate(@requests, plate_template, @robot, @batch, @plate_purpose)
    end
    @plates = @map_info[0]
    @source_plate_ids = @map_info[1]

    @plate_cols = Map.plate_width(plate_template.size)
    @plate_rows = Map.plate_length(plate_template.size)
  end

  def setup_input_params_for_pass_through
    @robot = Robot.find((params[:robot])["0"].to_i)
    @plate_type = params[:plate_type]
    @volume_required= params[:volume_required]
    @micro_litre_volume_required= params[:micro_litre_volume_required]
    @concentration_required = params[:concentration_required]
    @minimum_volume = params[:minimum_volume]
    @maximum_volume = params[:maximum_volume]
    @total_nano_grams = params[:total_nano_grams]
    @cherrypick_action = params[:cherrypick][:action]
    @plate_purpose_id = params[:plate_purpose_id]
  end

  def do_cherrypick_task(task, params)
    plates = params[:plate]
    size = params[:plate_size]
    plate_type = params[:plate_type]

    ActiveRecord::Base.transaction do
      # Determine if there is a standard plate to use.
      partial_plate, plate_barcode = nil, params[:plate_barcode]
      unless plate_barcode.nil?
        partial_plate = Plate.find_by_barcode(plate_barcode) or raise ActiveRecord::RecordNotFound, "No plate with barcode #{plate_barcode.inspect}"
      end

      # Ensure that we have a plate purpose for any plates we are creating
      plate_purpose = PlatePurpose.find(params[:plate_purpose_id])

      # Configure the cherrypicking action based on the parameters
      cherrypicker = case params[:cherrypick_action]
        when 'nano_grams_per_micro_litre' then create_nano_grams_per_micro_litre_picker(params)
        when 'nano_grams'                 then create_nano_grams_picker(params)
        when 'micro_litre'                then create_micro_litre_picker(params)
        else raise StandardError, "Invalid cherrypicking type #{params[:cherrypick_action]}"
      end

      # We can preload the well locations so that we can do efficient lookup later.
      well_locations = Hash[Map.where_plate_size(partial_plate.try(:size) || size).in_row_major_order.map do |location|
        [location.description, location]
      end]

      # All of the requests we're going to be using should be part of the batch.  If they are not
      # then we have an error, so we can pre-map them for quick lookup.  We're going to pre-cache a
      # whole load of wells so that they can be retrieved quickly and easily.
      wells = Hash[Well.find(@batch.requests.map(&:target_asset_id), :include => :well_attribute).map { |w| [w.id,w] }]
      request_and_well = Hash[@batch.requests.all(:include => :request_metadata).map { |r| [r.id.to_i, [r, wells[r.target_asset_id]]] }]
      used_requests, plates_and_wells = [], Hash.new { |h,k| h[k] = [] }
      plates.each do |id, plate_params|
        # The first time round this loop we'll either have a plate, from the partial_plate, or we'll
        # be needing to create a new one.
        plate = partial_plate
        if plate.nil?
          barcode = PlateBarcode.create.barcode
          plate   = plate_purpose.create!(:do_not_create_wells, :name => "Cherrypicked #{barcode}", :size => size, :barcode => barcode)
        end

        # Set the plate type, regardless of what it was.  This may change the standard plate.
        plate.set_plate_type(plate_type) unless plate_type.nil?

        plate_params.each do |row, row_params|
          row = row.to_i
          row_params.each do |col, request_id|
            request, well = case
              when request_id.blank?           then next
              when request_id.match(/control/) then create_control_request_and_add_to_batch(task, request_id)
              else request_and_well[request_id.to_i] or raise ActiveRecord::RecordNotFound, "Cannot find request #{request_id.inspect}"
            end

            # NOTE: Performance enhancement here
            # This collects the wells together for the plate they should be on, and modifies
            # the values in the well data.  It *does not* save either of these, which means that
            # SELECT & INSERT/UPDATE are not interleaved, which affects the cache
            well.map = well_locations[Map.location_from_row_and_column(row, col.to_i+1)]
            cherrypicker.call(well, request)
            plates_and_wells[plate] << well
            used_requests << request
          end
        end

        # At this point we can consider ourselves finished with the partial plate
        partial_plate = nil
      end

      # Attach the wells into their plate for maximum efficiency.
      plates_and_wells.each do |plate, wells|
        wells.map { |w| w.well_attribute.save! ; w.save! }
        plate.wells.attach(wells)
      end

      # Now pass each of the requests we used and ditch any there weren't back into the inbox.
      used_requests.map(&:pass!)
      (@batch.requests-used_requests).each do |unused_request|
        unused_request.recycle_from_batch!(@batch)
        unused_request.target_asset.aliquots.clear
      end
    end
  end

  def create_control_request_and_add_to_batch(task,control_param)
    control_request = task.create_control_request_from_well(control_param) or raise StandardError, "Control request not created!"
    @batch.requests << control_request
    [control_request, control_request.target_asset]
  end
end
