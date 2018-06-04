
class AssignTagsToTubesTask < AssignTagsTask
  def do_task(workflow, params)
    workflow.do_assign_tags_to_destination_task(self, params)
  end

  def included_for_render_task
    [{ requests: [{ asset: [:map, :asset_groups, { primary_aliquot: :sample }] }, :target_asset, :batch_request] }, :pipeline]
  end
end
