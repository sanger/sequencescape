module RequestsHelper #:nodoc: all
  def request_status(request)
    return if request.state.blank?
    if request.state == "pending"
      %Q{<strong style="color:#3c3c3c;">PENDING</strong>}
    elsif request.state == "started"
      %Q{<strong style="color:#0066ff;">STARTED</strong>}
    elsif request.state == "passed"
      %Q{<strong style="color:#008800;">PASSED</strong>}
    elsif request.state == "failed"
      %Q{<strong style="color:#880000;">FAILED</strong>}
    else
      %Q{<strong style="color:#3c3c3c;">#{request.state.upcase}</strong>}
    end
  end

  def read_length(request)
    if request.descriptor_value_for_key("read_length")
      "(#{request.descriptor_value_for_key("read_length").value} cycles)"
    end
  end
end