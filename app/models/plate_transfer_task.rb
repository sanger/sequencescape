#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class PlateTransferTask < Task

  belongs_to :purpose

  def render_task(workflow, params)
    workflow.render_plate_transfer_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_plate_transfer_task(self, params)
  end

  def partial
    self.class.to_s.underscore.chomp('_task')
  end

  def included_for_render_task
    [:pipeline]
  end

end
