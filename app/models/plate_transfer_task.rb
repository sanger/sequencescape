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

end
