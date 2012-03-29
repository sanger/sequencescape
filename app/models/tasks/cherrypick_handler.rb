module Tasks::CherrypickHandler
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
    end

    @batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
    @requests = @batch.ordered_requests

    unless @batch.started? || @batch.failed?
      @batch.start!(current_user)
    end

    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
    if @spreadsheet_layout
      @map_info = @spreadsheet_layout
    else
      @map_info = @task.map_wells_to_plates(@requests,plate_template,@robot,@batch,@plate)
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
  end

  def do_cherrypick_task(task, params)
    plates = params[:plate]
    size = params[:plate_size]
    plate_type = params[:plate_type]
    plate_barcode = params[:plate_barcode]
    volume_required= params[:volume_required]
    concentration_required = params[:concentration_required]
    cherrypick_action = params[:cherrypick_action]

    used_request_ids = {}
    ActiveRecord::Base.transaction do
      plates.each do |id, plate_params|
        plate = nil
        if plate_barcode.nil?
          # Plate barcode service must be running
          barcode = PlateBarcode.create.barcode
          plate = Plate.create(:name => "Cherrypicked #{barcode}", :size => size, :barcode => barcode)
        else
          plate = Plate.find_by_barcode(plate_barcode)
        end
 
        plate_params.each do |row, row_params|
          row = row.to_i
          row_params.each do |col, request_id|
            if request_id.match(/control/)
              request_id = create_control_request_and_add_to_batch(task, request_id)
            end
 
            request_id = request_id.to_i
            next if request_id == 0
            col = col.to_i
 
            request = Request.find request_id
            raise Exception.new, "No target asset for request: #{request_id}" unless request
            well = request.target_asset
            used_request_ids[request_id] = well
 
            if params[:cherrypick_action] == 'nano_grams_per_micro_litre'
              well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume_required.to_f,concentration_required.to_f,request.asset.get_concentration)
            elsif params[:cherrypick_action] == "nano_grams"
              well.volume_to_cherrypick_by_nano_grams(params[:minimum_volume].to_f, params[:maximum_volume].to_f, params[:total_nano_grams].to_f ,request.asset)
            elsif params[:cherrypick_action] == "micro_litre"
              well.volume_to_cherrypick_by_micro_litre(params[:micro_litre_volume_required].to_f)
            else
              raise 'Invalid cherrypicking type'
            end
            
            plate.add_well(well, row, col)
            well.save!
          end
 
          plate.set_plate_type(plate_type) unless plate_type.nil?
          plate.save!
        end
 
      end

      # Remove requests not put on plates.
      requests_to_pass, requests_to_remove = @batch.requests.partition { |r| not used_request_ids[r.id].nil? }
      requests_to_pass.each { |r| r.pass! }
      requests_to_remove.each do |r| 
        r.recycle_from_batch!(@batch)
        r.target_asset.aliquots.clear
      end
    end
  end

  def create_control_request_and_add_to_batch(task,control_param)
    control_request  = task.create_control_request_from_well(control_param)
    raise "Control request not created" if control_request.nil?
    @batch.requests << control_request

    control_request.id
  end

end
