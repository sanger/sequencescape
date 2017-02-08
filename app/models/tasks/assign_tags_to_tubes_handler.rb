# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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
