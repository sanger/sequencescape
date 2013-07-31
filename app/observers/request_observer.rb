  class RequestObserver < ActiveRecord::Observer

    def after_create(request)
      request.request_events.create!(
        :event_name   => 'created',
        :to_state     => request.state,
        :current_from => DateTime.now
      )
    end

    def before_save(request)
      return if request.new_record? || !request.changed.include?('state')
      from_state = request.changes['state'].first
      time = DateTime.now
      request.current_request_event.expire!(time)
      request.request_events.create!(
        :event_name   => 'state_changed',
        :from_state   => from_state,
        :to_state     => request.state,
        :current_from => time
      )
    end

    def before_destroy(request)
      time = DateTime.now
      request.current_request_event.expire!(time)
      request.request_events.create!(
        :event_name   => 'destroyed',
        :from_state   => request.state,
        :to_state     => request.state,
        :current_from => time,
        :current_to   => time
      )
    end

  end
