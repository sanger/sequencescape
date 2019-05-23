# An unused {Task}
# Assigns tagged tube into single plexed wells on the target plate.
#
# @deprecated Unused in production. Should be safe to delete. May need to clean up tests though.
#
# @see Tasks::AssignTubesToWellsHandler for behaviour included in the {WorkflowsController}
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
