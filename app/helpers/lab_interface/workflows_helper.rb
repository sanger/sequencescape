module LabInterface::WorkflowsHelper

  def descriptor_value(descriptor)
    value = ""
    unless @study.nil?
      value = @study.descriptor_value(descriptor.name)
    end

    unless @values.nil?
      unless @values[descriptor.name].nil?
        value = @values[descriptor.name]
      end
    end

    value

  end

  def link_to_comments(request)
     link_to_if(request.comments.present?, pluralize(request.comments.size, 'comment'),  request_comments_url(request)) { "None"}
  end

  def shorten(string)
    truncate string, 10, "..."
  end

  def not_so_shorten(string)
    truncate string, 15, "..."
  end

  def qc_select_box(request, status, html_options={})
    select_options = [ 'pass', 'fail' ]
    select_options.unshift('') if html_options.delete(:generate_blank)
    select_tag("#{request.id}[qc_state]", options_for_select(select_options, status), html_options.merge(:class => 'qc_state'))
  end

  def gel_qc_select_box(request, status, html_options={})
    blank = html_options.delete(:generate_blank) ? "<option></option>" : ""
    if status.blank? || status == "Pass"
      status = "OK"
    end
    select_tag("wells[#{request.id}][qc_state]", options_for_select({"Pass"=>"OK", "Fail"=>"Fail", "Weak"=>"Weak", "No Band"=>"Band Not Visible", "Degraded"=>"Degraded"}, status), html_options)
  end

end
