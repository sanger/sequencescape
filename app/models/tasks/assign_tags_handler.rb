# frozen_string_literal: true
# Handles the behaviour of {AssignTagsTask} and included in {WorkflowsController}
# {include:AssignTagsTask}
module Tasks::AssignTagsHandler
  def render_assign_tags_task(_task, params)
    @tag_group = TagGroup.find(params[:tag_group])
    @requests = @batch.requests
    @tags = @tag_group.tags.sorted
    @rits = @batch.pipeline.request_information_types
  end

  # rubocop:todo Metrics/MethodLength
  def do_assign_tags_task(_task, params) # rubocop:todo Metrics/AbcSize
    if params[:mx_library_name].blank?
      flash[:warning] = 'Multiplexed library needs a name'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return false
    end
    if MultiplexedLibraryTube.exists?(name: params[:mx_library_name])
      flash[:warning] = 'Name already in use.'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return false
    end

    @tag_group = TagGroup.find(params[:tag_group])

    ActiveRecord::Base.transaction do
      multiplexed_library =
        Tube::Purpose.standard_mx_tube.create!(name: params[:mx_library_name], barcode: AssetBarcode.new_barcode)
      @batch.requests.each do |request|
        tag_id = params[:tag][request.id.to_s] or next
        tag = @tag_group.tags.find(tag_id)
        tag.tag!(request.target_asset)

        AssetLink.create_edge(request.target_asset.labware, multiplexed_library)

        request
          .next_requests
          .select(&:pending?)
          .each { |sequencing_request| sequencing_request.update!(asset: multiplexed_library) }

        TransferRequest.create!(
          asset: request.target_asset,
          target_asset: multiplexed_library.receptacle,
          state: 'passed'
        )
      end
    end

    true
  end
  # rubocop:enable Metrics/MethodLength
end
