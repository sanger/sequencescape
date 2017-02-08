# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class TagGroupsTask < Task
  class TagGroupsData < Task::RenderElement
    alias_attribute :well, :asset
    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && TagGroupsData.new(request)
  end

  def partial
    'tag_groups_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_tag_groups_task(self, params)
  end

  def do_task(_workflow, _params)
    true
  end
end
