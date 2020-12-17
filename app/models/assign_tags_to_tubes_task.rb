# A {Task} used in {PacBioSamplePrepPipeline library creation pipelines}
# Applies the selected tags to the {LibraryTube library tubes}.
#
# @note At time of writing (3/4/2019) this is used in:
#   "PacBio Tagged Library Prep"
#
# @see Tasks::AssignTagsToTubesHandler for behaviour included in the {WorkflowsController}
class AssignTagsToTubesTask < AssignTagsTask
  def do_task(workflow, params)
    workflow.do_assign_tags_to_destination_task(self, params)
  end

  def included_for_render_task
    [{ requests: [{ asset: [:map, :asset_groups, { primary_aliquot: :sample }] }, :target_asset, :batch_request] },
     :pipeline]
  end
end
