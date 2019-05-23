# Handles the behaviour of {AssignTagsToTubesTask} and included in {WorkflowsController}
# {include:AssignTagsToTubesTask}
module Tasks::AssignTagsToTubesHandler
  def do_assign_tags_to_destination_task(_task, params)
    @tag_group = TagGroup.find(params[:tag_group])

    ActiveRecord::Base.transaction do
      @batch.requests.each do |request|
        tag_id = params[:tag][request.id.to_s] or next
        tag    = @tag_group.tags.find(tag_id)
        tag.tag!(request.target_asset)
      end
    end

    true
  end
end
