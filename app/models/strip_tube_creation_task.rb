#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class StripTubeCreationTask < Task

  belongs_to :purpose

  def render_task(workflow, params)
    workflow.render_strip_tube_creation_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_strip_tube_creation_task(self, params)
  end

  def partial
    self.class.to_s.underscore.chomp('_task')
  end

end
