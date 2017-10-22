# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

module ApplicationHelper
  # Should return either the custom text or a blank string
  def custom_text(identifier, differential = nil)
    Rails.cache.fetch("#{identifier}-#{differential}") do
      custom_text = CustomText.find_by(
        identifier: identifier,
        differential: differential
      )

      # .debug
      #  "No custom text found for #{identifier} #{differential}." if custom_text.nil?

      custom_text.try(:content) || ''
    end
  end

  def loading_bar(identifier = 'loading')
    content_tag('div', id: identifier, class: 'loading_bar', style: 'display:none') do
      image_tag 'loader-bar.gif', size: '200x19'
    end
  end

  def remote_error(identifier = 'remote_error')
    content_tag('div', id: identifier, class: 'error', style: 'display:none;') do
      'An error has occurred and the results can not be shown at the moment'
    end
  end

  def display_for_setting(setting)
    display = true
    if logged_in?
      if current_user.setting_for? setting
        if current_user.value_for(setting) == 'hide'
          display = false
        end
      end
    end
    display
  end

  def required_marker
    content_tag(:span, '&raquo;'.html_safe, class: 'required')
  end

  def render_flashes
    output = String.new.html_safe
    flash.each do |key, message|
      output << alert(key, id: "message_#{key}") do
        Array(message).reduce(String.new.html_safe) { |buffer, m| buffer << content_tag(:div, m) }
      end
    end
    output
  end

  def api_data
    { api_version: RELEASE.api_version }
  end

  def display_user_guide(display_text, link = nil)
    alert(:info) do
      link.present? ? link_to(display_text, link) : display_text
    end
  end

  def display_user_error(display_text, link = nil)
    alert(:danger) do
      link.present? ? link_to(display_text, link) : display_text
    end
  end

  def display_status(status)
    content_tag(:span, status, class: "request-state label label-#{bootstrapify_request_state(status)}")
  end

  def dynamic_link_to(summary_item)
    object = summary_item.object
    if object.instance_of?(Asset)
        return link_to((object.name).to_s, asset_path(object))
    elsif object.instance_of?(Request)
        return link_to("Request #{object.id}", request_path(object))
    else
      return 'No link available'
    end
  end

  def request_count_link(study, asset, state, request_type)
    matching_requests   = asset.requests.select { |request| (request.request_type_id == request_type.id) and request.state == state }
    html_options, count = { title: "#{asset.display_name} #{state}" }, matching_requests.size

    # 0 requests => no link, just '0'
    # 1 request  => request summary page
    # N requests => summary overview
    if count == 1
       url_path = request_path(matching_requests.first)
       link_to count, url_path, html_options
    elsif count > 1
       url_path = study_requests_path(study, state: state, request_type_id: request_type.id, asset_id: asset.id)
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
      'Unfollow ' + msg
    else
      'Follow ' + msg
    end
  end

  def progress_bar(count)
    color = ''
    if count < 25
      color = 'ccaaaa'
    elsif count > 99
      color = 'aaddaa'
    else
      color = 'DAEE34'
    end

    # TODO: Refactor this to use the bootstrap styles
    content_tag(:span, count, style: 'display:none') <<
      content_tag(:div, style: 'width: 100px; background-color: #CCCCCC; color: inherit;') do
        content_tag(:div, "#{count}%", style: "width: #{count}px; background-color: ##{color}; color: inherit; text-align:center")
      end
  end

  def completed(object, request_type = nil, cache = {})
    total  = 0
    passed = 0
    failed = 0

    if request_type

      if cache.blank?
        total = object.requests.request_type(request_type).size
        passed = object.requests.request_type(request_type).passed.count
        failed = object.requests.request_type(request_type).failed.count
      else
        passed_cache = cache[:passed]
        failed_cache = cache[:failed]
        total_cache  = cache[:total]

        total = total_cache[request_type][object.id]
        passed = passed_cache[request_type][object.id]
        failed = failed_cache[request_type][object.id]

      end
    else
      total = object.requests.request_type(request_type).size
      passed = object.requests.passed.size
      failed = object.requests.failed.size
    end

    if (total - failed) > 0
      return ((passed.to_f / (total - failed).to_f) * 100).to_i
    else
      return 0
    end
  end

  def study_state(state)
    if state == 'active'
      "<span style='color:green;'>#{state}</span>".html_safe
    else
      "<span style='color:red;'>#{state}</span>".html_safe
    end
  end

  def display_empty_table(display_text, link = nil)
    if link.nil?
      content_tag(:div, display_text, class: 'empty_table', id: 'empty_table')
    else
      content_tag(:div, link_to(display_text, link), class: 'empty_table', id: 'empty_table')
    end
  end

  ## From Pipelines

  def render_title(title = '')
    add :title, title
  end

  def render_help(help = '')
    add :help, help
  end

  def tabulated_error_messages_for(*params)
    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
    objects = params.collect { |object_name| instance_variable_get("@#{object_name}") }.compact
    count   = objects.inject(0) { |sum, object| sum + object.errors.count }
    if count.zero?
      ''
    else
      error_messages = objects.map { |object| object.errors.full_messages.map { |msg| content_tag(:div, msg) } }.join
      [content_tag(:td, class: 'error item') do
        "Your #{params.first} has not been created."
      end,
      content_tag(:td, class: 'error') do
        raw(error_messages)
      end].join.html_safe
    end
  end

  def horizontal_tab(name, key, related_div, tab_no, selected = false)
    link_to raw(name.to_s), 'javascript:void(0);', 'data-tab-refers': "##{related_div}", 'data-tab-group': tab_no, id: key.to_s, class: "#{selected ? "selected " : ""}tab#{tab_no}"
    # link_to raw("#{name}"), "javascript:void(0);", :onclick => %Q{swap_tab("#{key}", "#{related_div}", "#{tab_no}");}, :id => "#{key}", :class => "#{selected ? "selected " : ""}tab#{tab_no}"
  end

  def item_status(item)
    if item.failures.empty?
      ''
    else
      '<span style="color:red;">FAILED</span>'
    end
  end

  def display_complex_content(hash_content)
    hash_content.each do |key, value|
      case key
      when 'criterion'
        output = ''
        value.each do |v|
          output = output + content_tag(:span, "<strong>#{v.inspect}</strong>")
          output = output + content_tag(:br)
        end
        return output
      when 'link'
        return link_to(value['label'], value['href'])
      end
    end
  end

  def display_ready_for_manual_qc(v)
    if v
      image_tag('accept.png')
    else
      image_tag('error.png')
    end
  end

  def display_request_information(request, rit, batch = nil)
    r = request.value_for(rit.name, batch)
    (!r || r.empty?) ? 'NA' : r
  end

  def display_boolean_results(result)
    return 'NA' if (!result || result.empty?)
    if result == 'pass' || result == '1' || result == 'true'
      return image_tag('accept.png', title: result)
    else
      return image_tag('error.png', title: result)
    end
  end

  def sorted_requests_for_search(requests)
    sorted_requests = requests.select { |r| r.pipeline_id.nil? }
    new_requests = requests - sorted_requests
    new_requests.sort_by(&:pipeline_id)
    requests = requests + sorted_requests
  end

  def display_hash_value(hash, key, sub_key)
    hash.fetch(key, {}).fetch(sub_key, '')
  end

  # Creates a label that is hidden from the view so that testing is easier
  def hidden_label_tag_for_testing(name, text = nil, options = {})
    label_tag(name, text, options.merge(style: 'display:none;'))
  end

  def non_breaking_space
    '&nbsp;'.html_safe
  end

  def help_text(_label_text = nil, suggested_id = nil, &block)
    content = capture(&block)
    return if content.blank?
    tooltip_id = "prop_#{suggested_id || content.hash}_help"
    tooltip('?', id: tooltip_id, &block)
  end

  # The admin email address should be stored in config.yml for the current environment
  def help_email_link
    admin_address = configatron.admin_email || 'admin@test.com'
    link_to admin_address.to_s, "mailto:#{admin_address}"
  end
end
