# frozen_string_literal: true
class EventSender
  def self.send_fail_event(request, reason, comment, batch_id)
    send_state_event('fail', request, reason, comment, batch_id)
  end

  def self.send_pass_event(request, reason, comment, batch_id)
    send_state_event('pass', request, reason, comment, batch_id)
  end

  def self.send_state_event(state, request, reason, comment, batch_id, user = nil) # rubocop:todo Metrics/ParameterLists
    hash = {
      eventful: request,
      family: state,
      content: reason,
      message: comment,
      identifier: batch_id,
      created_by: user
    }
    create!(hash)
  end

  def self.send_request_update(request, family, message, options = nil)
    hash = { eventful: request, family: family, message: message }
    create!(hash.merge(options || {}))
  end

  def self.send_pick_event(well, purpose_name, message, options = nil)
    hash = {
      eventful: well,
      family: PlatesHelper.event_family_for_pick(purpose_name),
      message: message,
      content: Date.today.to_s
    }
    create!(hash.merge(options || {}))
  end


  def self.create!(hash = {})
    hash.delete(:key)
    Event.create!(hash)
  end
end
