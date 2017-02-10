# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class MultiplexedCherrypickingTask < Task
  include Tasks::PlatePurposeBehavior

  belongs_to :purpose

  class AssignTubesToWellsData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def partial
    'assign_wells_to_wells'
  end

  def included_for_do_task
    [{ requests: :asset }, :pipeline]
  end

  def included_for_render_task
    [{ requests: :asset }, :pipeline]
  end

  def create_render_element(request)
    request.asset && AssignTubesToWellsData.new(request)
  end

  def render_task(workflow, params)
    super
    workflow.set_plate_purpose_options(self)
  end

  def do_task(workflow, params)
    destination_plate = target_plate(params[:existing_plate_barcode], params[:plate_purpose_id])
    workflow.do_assign_requests_to_multiplexed_wells_task(self, params, destination_plate) &&
    workflow.do_assign_pick_volume_task(self, params)
  end

  def target_plate(barcode, plate_purpose_id)
    return Plate.with_machine_barcode(barcode).first unless barcode.blank?
    PlatePurpose.find(plate_purpose_id).create!
  end
end
