class AssignPlatePurposeTask < Task
  # Checks that request has an asset and if so returns a new
  # AssignPlatePurposeData using request.

  include Tasks::PlatePurposeBehavior
  def create_render_element(request)
  end

  # Returns the name of the partial used to display this task,
  # which is the classname of the task in snake_case - '_task'
  # e.g. 'assign_plate_purpose'
  def partial
    self.class.to_s.underscore.chomp('_task')
  end

  # Calls the corresponding render task method in the controller.
  def render_task(workflows_controller, params)
    super
    workflows_controller.render_assign_plate_purpose_task(self,params)
  end

  # Calls the corresponding do method in the controller.
  def do_task(workflows_controller, params)
    workflows_controller.do_assign_plate_purpose_task(self, params)
  end

  # Returns the default value to be used for this plate.
  def plate_purpose_id
    2
  end

end
