module Tasks::AssignPlatePurposeHandler
  def do_assign_plate_purpose_task(task,params)
    task_params = params[:assign_plate_purpose_task]
    plate_purpose = PlatePurpose.find(task_params[:plate_purpose_id])

    if @batch.output_plates.blank?
      flash[:error] = "This batch has no output plates to set a purpose for"
      return false
    else
      @batch.set_output_plate_purpose(plate_purpose)
      @batch.save!
      flash[:notice] = "Output plate purpose successfully set."
      true
    end
  end

  # Sets up instance variables so that the task's partial can be rendered.
  def render_assign_plate_purpose_task(task,params)
    @potential_plate_purposes = PlatePurpose.all
    @plate_purpose_options = plate_purpose_options()
  end

  # Returns a list of valid plate purpose types based on the requests in the current batch.
  def plate_purpose_options
    requests       = @batch.requests.map { |r| r.submission.next_requests(r) }.flatten
    plate_purposes = requests.map(&:request_type).compact.uniq.map(&:acceptable_plate_purposes).flatten.uniq
    plate_purposes = PlatePurpose.all if plate_purposes.empty?  # Fallback situation for the moment
    plate_purposes.map { |p| [p.name, p.id] }.sort
  end
  private :plate_purpose_options
end
