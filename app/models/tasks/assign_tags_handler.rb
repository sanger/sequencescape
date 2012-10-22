module Tasks::AssignTagsHandler
  def render_assign_tags_task(task, params)
    @tag_group = TagGroup.find(params[:tag_group])
    @requests = @batch.ordered_requests
    @tags = @tag_group.tags.sorted
    @rits = @batch.pipeline.request_information_types
  end

  def do_assign_tags_task(task, params)
    if params[:mx_library_name].blank?
      flash[:warning] = "Multiplexed library needs a name"
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (@stage -1).to_s
      return false
    end
    if MultiplexedLibraryTube.find_all_by_name(params[:mx_library_name]).size > 0
      flash[:warning] = "Name already in use."
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (@stage -1).to_s
      return false
    end

    @tag_group = TagGroup.find(params[:tag_group])

    ActiveRecord::Base.transaction do
      multiplexed_library = Tube::Purpose.standard_mx_tube.create!(:name => params[:mx_library_name], :barcode => AssetBarcode.new_barcode)
      @batch.requests.each do |request|
        tag_id = params[:tag][request.id.to_s] or next
        tag    = @tag_group.tags.find(tag_id)
        tag.tag!(request.target_asset)

        AssetLink.create_edge(request.target_asset, multiplexed_library)
        RequestType.transfer.create!(:asset => request.target_asset, :target_asset => multiplexed_library, :state => 'passed')

        request.next_requests(@batch.pipeline).each do |sequencing_request|
          sequencing_request.update_attributes!(:asset => multiplexed_library)
        end
      end
    end

    true
  end
end
