# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

module Tasks::CherrypickGroupBySubmissionHandler
  def do_cherrypick_group_by_submission_task(task, params)
    unless task.valid_params?(params)
      flash[:warning] = 'Invalid values typed in'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (0).to_s
      return false
    end

    # If there was a plate scanned then we take its purpose, otherwise we use the purpose specified
    # in the dropdown.
    partial_plate, plate_purpose = nil, PlatePurpose.find(params[:plate_purpose_id])
    unless params[:existing_plate].blank?
      partial_plate, plate_purpose = Plate.with_machine_barcode(params[:existing_plate]).first, nil
      if partial_plate.nil?
        flash[:error] = "Cannot find the partial plate #{params[:existing_plate].inspect}"
        redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (0).to_s
        return false
      end
      unless task.plate_purpose_options(@batch).include?(@plate.purpose)
        flash[:error] = 'Invalid target plate, wrong plate purpose'
        redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
        return
      end
    end

    robot = Robot.find(params[:robot_id])
    batch = Batch.includes([:requests, :pipeline, :lab_events]).find(params[:batch_id])

    cherrypick_action = params[:cherrypick][:action]

    ActiveRecord::Base.transaction do
      task.send(
        :"pick_by_#{cherrypick_action}",
        batch.ordered_requests, robot, partial_plate || plate_purpose, params[cherrypick_action]
      )
    end

    true
  rescue => exception
    flash[:error] = exception.message
    false
  end

  def render_cherrypick_group_by_submission_task(task, _params)
    @plate_purpose_options = task.plate_purpose_options(@batch)
  end
end
