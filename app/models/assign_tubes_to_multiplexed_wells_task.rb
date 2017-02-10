# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AssignTubesToMultiplexedWellsTask < Task
  belongs_to :purpose

  class AssignTubesToWellsData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def partial
    'assign_tubes_to_wells'
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
  end

  def do_task(workflow, params)
    workflow.do_assign_requests_to_multiplexed_wells_task(self, params)
  end
end
