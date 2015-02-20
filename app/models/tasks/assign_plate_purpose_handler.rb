#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module Tasks::AssignPlatePurposeHandler
  def do_assign_plate_purpose_task(task,params)
    if @batch.output_plates.blank?
      flash[:error] = "This batch has no output plates to set a purpose for"
      return false
    end

    ActiveRecord::Base.transaction do
      task_params = params[:assign_plate_purpose_task]
      plate_purpose = PlatePurpose.find(task_params[:plate_purpose_id])

      @batch.set_output_plate_purpose(plate_purpose)
      @batch.save!
      flash[:notice] = "Output plate purpose successfully set."
    end
    true
  end

  # Sets up instance variables so that the task's partial can be rendered.
  def render_assign_plate_purpose_task(task,params)
    @potential_plate_purposes = PlatePurpose.all
    @plate_purpose_options = task.plate_purpose_options(@batch)
  end
end
