module Tasks::<%= singular_name.camelize %>Handler
  def render_<%= singular_name %>_task(task, params)
  end

  def do_<%= singular_name %>_task(task, params)
    true
  end
end
