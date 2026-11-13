# frozen_string_literal: true

# The Cucumber features used the seeded 'Cluster formation' sequencing pipelines. RSpec does not load the seeds,
# so these helpers build an equivalent pipeline and requests waiting in its inbox.
# Include it in a spec with `include ClusterFormationPipelineHelpers`.
module ClusterFormationPipelineHelpers
  # The sequencing pipeline factory always adds a control request type. Set the controls argument to false to remove it,
  # like the seeded 'Cluster formation SE (no controls)' pipeline. The column cannot be null, so like the seeds
  # it is set to 0, which matches no request type.
  def create_cluster_formation_pipeline(name, task_names: ['Specify Dilution Volume'], controls: true)
    pipeline =
      create(:sequencing_pipeline, name: name, workflow: build(:lab_workflow_for_pipeline, name: name, item_limit: 8))
    pipeline.update!(control_request_type_id: 0) unless controls
    task_names.each.with_index(1) do |task_name, sorted|
      create(:set_descriptors_task, name: task_name, workflow: pipeline.workflow, sorted: sorted, batched: true)
    end
    pipeline
  end

  # Creates a request in the pipeline inbox, on a library tube that has been scanned into the lab
  def create_cluster_formation_request(pipeline)
    create(
      :sequencing_request_with_assets,
      request_type: pipeline.request_types.first,
      asset: create(:library_tube, :scanned_into_lab),
      target_asset: nil,
      submission: create(:submission)
    )
  end
end
