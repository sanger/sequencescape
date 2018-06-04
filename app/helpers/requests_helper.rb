
module RequestsHelper #:nodoc: all
  def request_status(request)
    state = request.state.presence || 'unknown'
    content_tag(:span, state.upcase, class: "request-state text-#{bootstrapify(state.downcase)}")
  end

  def read_length(request)
    if request.descriptor_value_for_key('read_length')
      "(#{request.descriptor_value_for_key("read_length").value} cycles)"
    end
  end
end
