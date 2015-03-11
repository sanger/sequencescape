class AssignTagsToTubesTask < AssignTagsTask
  def do_task(workflow, params)
    workflow.do_assign_tags_to_destination_task(self, params)
  end
end
