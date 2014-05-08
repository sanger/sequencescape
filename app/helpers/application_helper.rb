module ApplicationHelper

  # Should return either the custom text or a blank string
  def custom_text(identifier, differential = nil)
    Rails.cache.fetch("#{identifier}-#{differential}") do
      custom_text = CustomText.first(
        :conditions => {
          :identifier   => identifier,
          :differential => differential
        }
      )

      RAILS_DEFAULT_LOGGER.debug
        "No custom text found for #{identifier} #{differential}." if custom_text.nil?

      custom_text.try(:content) || ""
    end

  end

  def loading_bar(identifier = "loading")
    content_tag("div", :id => identifier, :class => "loading_bar", :style => "display:none") do
      image_tag "loader-bar.gif", :size => "200x19"
    end
  end

  def remote_error(identifier = "remote_error")
    content_tag("div", :id => identifier, :class=>"error", :style => "display:none;") do
      "An error has occurred and the results can not be shown at the moment"
    end
  end

  def display_for_setting(setting)
    display = true
    if logged_in?
      if current_user.setting_for? setting
        if current_user.value_for(setting) == "hide"
          display = false
        end
      end
    end
    display
  end

  def required_marker
    output = %Q{<span class="required">&raquo;</span>}
  end

  def required_marker_bold
    %Q{<span style="font-size : medium;"class="required">&raquo;</span>}
  end

  def render_flashes
    output = ""
    flash.merge(action_flash).each do |key, message|
      content = message
      content = message.map { |m| content_tag(:div, m) }.join if message.is_a?(Array)
      output << content_tag(:div, content, :class => 'flash', :id => "message_#{ key }")
    end
    return output
  end

  def api_data
    {:api_version => RELEASE.api_version}
  end

  def display_user_guide(display_text, link=nil)
    if link.nil?
      content_tag(:div, display_text, :class => "user_guide")
    else
      content_tag(:div, link_to(display_text, link), :class => "user_guide")
   end
  end

  def display_user_error(display_text, link=nil)
    unless link.nil?
      content_tag(:div, link_to(display_text, link), :class => "user_error")
    else
      content_tag(:div, display_text, :class => "user_error")
   end
  end

  def display_status(status)
    case status
      when "passed"
        formatted_status = "<span style='color:green;font-weight:bold;'>Passed</span>"
      when "failed"
        formatted_status = "<span style='color:red;font-weight:bold;'>Failed</span>"
      when "started"
        formatted_status = "<span style='color:blue;font-weight:bold;'>Started</span>"
      when "pending"
        formatted_status = "<span style='font-weight:bold;'>Pending</span>"
      when "completed"
        formatted_status = "<span style='color:green;font-weight:bold;'>Completed</span>"
      else
        formatted_status = "<span style='font-weight:bold;'>#{status.humanize}</span>"
    end
    return formatted_status
  end

  def dynamic_link_to(summary_item)
    object = summary_item.object
    if object.instance_of?(Asset)
        return link_to("#{object.name}", asset_path(object))
    elsif object.instance_of?(Request)
        return link_to("Request #{object.id}", request_path(object))
    else
      return 'No link available'
    end
  end

  def request_count_link(study, asset, state, request_type)
    matching_requests   = asset.requests.select { |request| (request.request_type == request_type) and request.send(:"#{ state }?") }
    html_options, count = { :title => "#{ asset.display_name } #{ state }" }, matching_requests.size

    # 0 requests => no link, just '0'
    # 1 request  => request summary page
    # N requests => summary overview
    if count == 1
       url_path = request_path(matching_requests.first)
       link_to count, url_path, html_options
    elsif count > 1
       url_path = study_requests_path(study, :state => state, :request_type_id => request_type.id, :asset_id => asset.id)
       link_to count, url_path, html_options
    end

  end

  def request_link(object, count, request_type, status = nil, options = {}, link_options = {})
    link_to_if((count != 0), count, request_list_path(object, request_type, status, options), link_options)
  end

  def request_list_path(object, request_type = nil, status = nil, options = {})
    options[:state] = status unless status.nil?
    options[:request_type_id] = request_type.id unless request_type.nil?

    if object.instance_of?(Asset)
      asset_path(object, options)
    elsif object.instance_of?(Study)
      study_requests_path(object, options)
    end
  end

  def display_follow(item, user, msg)
    if user.following?(item)
      "Unfollow " + msg
    else
      "Follow " + msg
    end
  end

  def progress_bar(count)
    color = ""
    if count < 25
      color = "ccaaaa"
    elsif count > 99
      color = "aaddaa"
    else
      color = "DAEE34"
    end

    html = %Q{<span style="display:none">#{count}</span>}
    html = html + %Q{<div style="width: 100px; background-color: #CCCCCC; color: inherit;">}
    html = html + %Q{<div style="width: #{count}px; background-color: ##{color}; color: inherit;">}
    html = html + %Q{<center>#{count}%</center>}
    html = html + %Q{  </div>}
    html = html + %Q{</div>}
  end

  def completed(object, request_type = nil, cache = {})

    total  = 0
    passed = 0
    failed = 0

    if request_type

      unless cache.blank?
        passed_cache = cache[:passed]
        failed_cache = cache[:failed]
        total_cache  = cache[:total]

        total = total_cache[request_type][object.id]
        passed = passed_cache[request_type][object.id]
        failed = failed_cache[request_type][object.id]

      else
        total = object.requests.request_type(request_type).size
        passed = object.requests.request_type(request_type).passed.count
        failed = object.requests.request_type(request_type).failed.count
      end
    else
      total = object.requests.request_type(request_type).size
      passed = object.requests.passed.size
      failed = object.requests.failed.size
    end

    if (total - failed) > 0
      return ((passed.to_f / (total - failed).to_f)*100).to_i
    else
      return 0
    end
  end

  def study_state(state)
    if state == "active"
      return "<span style='color:green;'>#{state}</span>"
    else
      return "<span style='color:red;'>#{state}</span>"
    end
  end

  def display_empty_table(display_text, link=nil)
    unless link.nil?
      content_tag(:div, link_to(display_text, link), :class => "empty_table", :id => "empty_table")
    else
      content_tag(:div, display_text, :class => "empty_table", :id => "empty_table")
   end
  end


  ## From Pipelines

  def render_title(title = "")
    add :title, title
  end

  def render_help(help = "")
    add :help, help
  end

  def required_marker
    output = %Q{<span class="required">&raquo;</span>}
  end

  def tabulated_error_messages_for(*params)
    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
    objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    count   = objects.inject(0) {|sum, object| sum + object.errors.count }
    unless count.zero?
      error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:div, msg) } }
      html = %Q{<td class="error item">Your #{params.first} has not been created.</td>}
      html = html + %Q{<td class="error">#{error_messages}</td>}
      html
    else
      ""
    end
  end

  def horizontal_tab(name, key, related_div, tab_no, selected = false)
     link_to "#{name}", "javascript:void(0);", :onclick => %Q{swap_tab("#{key}", "#{related_div}", "#{tab_no}");}, :id => "#{key}", :class => "#{selected ? "selected " : ""}tab#{tab_no}"
  end

  def item_status(item)
    if item.failures.empty?
      ""
    else
      %Q{<span style="color:red;">FAILED</span>}
    end
  end

  def display_complex_content(hash_content)
    hash_content.each do |key, value|
      case key
      when "criterion"
        output = ""
        value.each do |v|
          output = output + content_tag(:span, "<strong>#{v.inspect}</strong>")
          output = output + content_tag(:br)
        end
        return output
      when "link"
        return link_to(value["label"], value["href"])
      end
    end
  end

  def display_ready_for_manual_qc(v)
    if v
      image_tag("accept.png")
    else
      image_tag("error.png")
    end
  end

  def display_request_information(request, rit, batch = nil)
    r = request.value_for(rit.name, batch)
    (!r || r.empty?) ? "NA" : r
  end

  def display_boolean_results(result)
    return "NA" if (!result || result.empty?)
    if result == "pass" || result == "1" || result == "true"
      return image_tag("accept.png", :title => result)
    else
      return image_tag("error.png", :title => result)
    end
  end

  def sorted_requests_for_search(requests)
    sorted_requests = requests.select{|r| r.pipeline_id.nil?}
    new_requests = requests - sorted_requests
    new_requests.sort_by(&:pipeline_id)
    requests = requests + sorted_requests
  end

  def display_hash_value(hash, key, sub_key)
    hash.fetch(key, {}).fetch(sub_key, '')
  end

  # Creates a label that is hidden from the view so that testing is easier
  def hidden_label_tag_for_testing(name, text = nil, options = {})
    label_tag(name, text, options.merge(:style => 'display:none;'))
  end

  def help_text(label_text = nil, suggested_id = nil, &block)
    content = capture(&block)

    # TODO: This regexp isn't obvious until you stare at it for a while but:
    #   * The $1 is at least 20 characters long on match
    #   * $1 will end with a complete word (even if 20 characters is in the middle)
    #   * If there's no match then $1 is nil
    # Hence shortened_text is either nil or at least 20 characters
    shortened_text = (content =~ /^(.{20}\S*)\s\S/ and $1)

    if content.blank?
      concat('&nbsp;')
    elsif shortened_text.nil?
      concat(content)
    else
      concat(shortened_text)
      tooltip_id = "prop_#{suggested_id || content.hash}_help"
      concat(label_tag("tooltip_content_#{tooltip_id}", label_text, :style => 'display:none;'))

      tooltip('...', :id => tooltip_id, &block)
    end
  end

  # The admin email address should be stored in config.yml for the current environment
  def help_email_link
    admin_address = configatron.admin_email || "admin@test.com"
    link_to "#{admin_address}", "mailto:#{admin_address}"
  end
end
