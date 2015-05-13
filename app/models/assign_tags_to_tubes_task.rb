#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AssignTagsToTubesTask < AssignTagsTask
  def do_task(workflow, params)
    workflow.do_assign_tags_to_destination_task(self, params)
  end

  def included_for_render_task
    [{:requests=>[{:asset=>[:map,:asset_groups,{:primary_aliquot=>:sample}]},:target_asset,:batch_request]}, :pipeline]
  end

end
