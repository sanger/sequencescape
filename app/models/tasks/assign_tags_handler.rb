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
    target_request = @batch.requests.find_by_request_type_id(@batch.pipeline.request_type_id)
    requests = Request.find_all_by_submission_id(target_request.submission_id).select { |r| r.asset.nil? and r.pending? and r.request_type_id != @batch.pipeline.request_type_id }
    if target_request.nil? or requests.size == 0
      flash[:warning] = "Unable to find sequencing request."
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
      multiplexed_library = MultiplexedLibraryTube.create!(:name => params[:mx_library_name], :barcode => AssetBarcode.new_barcode)
      @batch.requests.each do |request|
        tag_id       = params[:tag][request.id.to_s] or next
        tag          = @tag_group.tags.find(tag_id)
        tag_instance = TagInstance.create!(:tag => tag)

        begin
        AssetLink.create_edge(tag_instance, request.target_asset)
        AssetLink.create_edge(request.target_asset, multiplexed_library)
        rescue => exception
          debugger
          raise
        end
      end

      # Find a request to get the submission_id from to find the sequencing request
      # TODO: Refactor in connection with Submission usage and Request#next_requests
      target_request = @batch.requests.find_by_request_type_id(@batch.pipeline.request_type_id)

      # Find based on item_id
      requests = Request.find_all_by_submission_id(target_request.submission_id).select { |r| r.asset.nil? and r.pending? and r.request_type_id != @batch.pipeline.request_type_id }
      requests.each do |target|
        target.asset = multiplexed_library
        target.save
      end
    end

    true
  end
end
