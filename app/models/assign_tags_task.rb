# A {Task} used in {LibraryCreationPipeline library creation pipelines}
# Applies the selected tags to the {LibraryTube library tubes}.
# Also appears to create and pool into a {MultiplexedLibraryTube}
#
# @note At time of writing (3/4/2019) this is used in:
#   "Illumina-B MX Library Preparation", "Illumina-C MX Library Preparation"
#   "PacBio Tagged Library Prep" (As a subclass)
#   Of those only "Illumina-C MX Library Preparation", "PacBio Tagged Library Prep" are active, and both have
#   replacements either in development or roadmapped.
#
# @see Tasks::AssignTagsHandler for behaviour included in the {WorkflowsController}
class AssignTagsTask < Task
  def included_for_render_task
    [{ requests: [{ asset: [:asset_groups, { primary_aliquot: :sample }] }, :target_asset, :batch_request] }, :pipeline]
  end

  def partial
    'assign_tags_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_assign_tags_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_assign_tags_task(self, params)
  rescue Aliquot::TagClash => e
    workflow.send(:flash)[:error] = e.message
    raise ActiveRecord::Rollback
  end
end
