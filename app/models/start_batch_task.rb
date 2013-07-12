class StartBatchTask < Task

  def render_task(controller, params)
    # Cheat, start the batch, then skip straight to the next task
    controller.do_start_batch_task(self,params)
  end

end
