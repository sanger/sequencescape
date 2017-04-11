# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Tasks::AssignTagsToWellsHandler
  def render_assign_tags_to_wells_task(task, params)
    @tag_group = TagGroup.find(params[:tag_group])
    @tags = @tag_group.tags
    @plate = task.find_plates_from_batch(params[:batch_id])
    requests = task.find_batch_requests(params[:batch_id])
    @tags_to_wells = task.map_tags_to_wells(@tag_group, @plate)
    @asset_ids_to_colour_index = task.map_asset_ids_to_normalised_index_by_submission(requests)
    begin
      task.validate_tags_not_repeated_for_submission!(requests, @tags_to_wells)
    rescue
      flash[:warning] = 'Duplicate tags will be assigned to a pooled tube, select a different tag group'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (0).to_s, tag_group: params[:tag_group]
      return false
    end
  end

  def do_assign_tags_to_wells_task(task, params)
    requests = task.find_batch_requests(params[:batch_id])
    begin
      task.validate_returned_tags_are_not_repeated_in_submission!(requests, params)
    rescue
      flash[:warning] = 'Duplicate tags in a single pooled tube'
      redirect_to action: 'stage', batch_id: @batch.id, workflow_id: @workflow.id, id: (0).to_s, tag_group: params[:tag_group]
      return false
    end

    ActiveRecord::Base.transaction do
      well_id_tag_id_map = {}
      params[:tag].each do |k, v|
        well_id_tag_id_map[k.to_i] = v.to_i
      end
      task.assign_tags_to_wells(requests, well_id_tag_id_map)
      # task.unlink_tag_instances_from_wells(requests)
      # task.create_tag_instances_and_link_to_wells(requests, params)
      # task.link_pulldown_indexed_libraries_to_multiplexed_library(requests)
    end

    true
  end
end
