#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
module Tasks::TagGroupHandler
  def render_tag_groups_task(task, params)
    @tag_groups = TagGroup.visible.all
  end
end
