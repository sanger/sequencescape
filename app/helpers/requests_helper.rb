# frozen_string_literal: true
module RequestsHelper #:nodoc: all
  def request_status(request)
    state = request.state.presence || 'unknown'
    tag.span(state.upcase, class: "request-state text-#{state.downcase}")
  end
end
