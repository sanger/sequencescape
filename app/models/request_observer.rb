class RequestObserver < ActiveRecord::Observer
  observe :request

  # Records the creation of a new request.  The initial state of to of the
  # request is based on the state machine used at the time of creation.
  def after_create(request)
    RequestEvent.create!(
      :request    => request,
      :to_state   => Request.state_machine.initial_state(request).human_name,
      :project    => request.initial_project,
      :study      => request.study,
      :event_name => 'create'
    )
  end

  def before_transition(request, transition)
    RequestEvent.create!(
      :request    => request,
      :from_state => transition.from,
      :to_state   => transition.to,
      :project    => request.initial_project,
      :study      => request.study,
      :event_name => transition.human_event
    )
  end

  def before_destroy(request)
    RequestEvent.create!(
      :request    => request,
      :from_state => request.state,
      :to_state   => 'destroyed',
      :project    => request.initial_project,
      :study      => request.study,
      :event_name => 'destroy'
    )
  end

  # Currently we're only interested in Study and Project changes
  def before_update(request)
    log_attr_update(request, 'initial_project_id') if request.changed.include?('initial_project_id')
    log_attr_update(request, 'study_id')           if request.changed.include?('study_id')
  end

  def log_attr_update(request, attr_name)
    attr_from, attr_to = request.changes[attr_name]

    RequestEvent.create!(
      :request    => request,
      :from_state => request.state,
      :to_state   => request.state,
      :project    => request.initial_project,
      :study      => request.study,
      :event_name => "ATTRIBUTE: #{attr_name} UPDATED: #{attr_from} -> #{attr_to}"
    )
  end
  private :log_attr_update

end
