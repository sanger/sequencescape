# frozen_string_literal: true
class PlateTransferTask < Task # rubocop:todo Style/Documentation
  belongs_to :purpose

  def render_task(workflows_controller, params, _user)
    ActiveRecord::Base.transaction { workflows_controller.render_plate_transfer_task(self, params) }
  end

  def do_task(workflows_controller, params, _user)
    workflows_controller.do_plate_transfer_task(self, params)
  end

  def partial
    self.class.to_s.underscore.chomp('_task')
  end

  def included_for_render_task
    [:pipeline]
  end
end
