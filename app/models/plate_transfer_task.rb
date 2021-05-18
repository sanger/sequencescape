class PlateTransferTask < Task # rubocop:todo Style/Documentation
  belongs_to :purpose

  def render_task(workflow, params)
    ActiveRecord::Base.transaction { workflow.render_plate_transfer_task(self, params) }
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
