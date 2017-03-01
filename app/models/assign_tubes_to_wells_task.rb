# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class AssignTubesToWellsTask < Task
  class AssignTubesToWellsData < Task::RenderElement
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && AssignTubesToWellsData.new(request)
  end

  def partial
    'assign_tubes_to_wells_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_assign_tubes_to_wells_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_assign_tubes_to_wells_task(self, params)
  end
end
