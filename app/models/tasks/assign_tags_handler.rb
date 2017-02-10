# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Tasks::AssignTagsHandler
  def render_assign_tags_task(_task, params)
    @tag_group = TagGroup.find(params[:tag_group])
    @requests = @batch.requests
    @tags = @tag_group.tags.sorted
    @rits = @batch.pipeline.request_information_types
  end

  def do_assign_tags_task(_task, params)
    if params[:mx_library_name].blank?
      flash[:warning] = 'Multiplexed library needs a name'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return false
    end
    if MultiplexedLibraryTube.where(name: params[:mx_library_name]).size > 0
      flash[:warning] = 'Name already in use.'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (@stage - 1).to_s
      return false
    end

    @tag_group = TagGroup.find(params[:tag_group])

    ActiveRecord::Base.transaction do
      multiplexed_library = Tube::Purpose.standard_mx_tube.create!(name: params[:mx_library_name], barcode: AssetBarcode.new_barcode)
      @batch.requests.each do |request|
        tag_id = params[:tag][request.id.to_s] or next
        tag    = @tag_group.tags.find(tag_id)
        tag.tag!(request.target_asset)

        AssetLink.create_edge(request.target_asset, multiplexed_library)

        request.next_requests(@batch.pipeline).each do |sequencing_request|
          sequencing_request.update_attributes!(asset: multiplexed_library)
        end

         RequestType.transfer.create!(asset: request.target_asset, target_asset: multiplexed_library, state: 'passed')
      end
    end

    true
  end
end
