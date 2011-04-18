module Tasks::CherrypickGroupBySubmissionHandler
  def do_cherrypick_group_by_submission_task(task,params)
    if ! task.valid_params?(params)
      flash[:warning] = "Invalid values typed in"
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (0).to_s
      return false
    end
    
    volume_required= params[:volume_required]
    concentration_required = params[:concentration_required]
    plate_purpose = PlatePurpose.find(params[:plate_purpose_id])

    begin
      barcode = PlateBarcode.create.barcode
      batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
      requests = batch.ordered_requests
      
      ActiveRecord::Base.transaction do
        plate = Plate.create!(:name => "Cherrypicked #{barcode}", :barcode => barcode, :plate_purpose => plate_purpose)
        if params[:cherrypick][:action] == 'nano_grams_per_micro_litre'
          task.pick_by_nano_grams_per_micro_litre(batch, requests, plate, plate_purpose, params)
        elsif params[:cherrypick][:action] == "nano_grams"
          task.pick_by_nano_grams(batch, requests, plate, plate_purpose, params)
        elsif params[:cherrypick][:action] == "micro_litre"
          task.pick_by_micro_litre(batch, requests, plate, plate_purpose, params)
        else
          raise 'Invalid cherrypicking type'
        end
      end
    rescue => exception
      flash[:error] = exception.message
      return false
    end

    true
  end



  def render_cherrypick_group_by_submission_task(task,params)
    @plate_purpose_options = plate_purpose_options()
  end

  private
  def plate_purpose_options
    PlatePurpose.all.map { |purpose| [purpose.name,purpose.id] }.sort
  end
end
