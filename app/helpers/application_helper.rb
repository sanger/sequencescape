module ApplicationHelper
  # Should return either the custom text or a blank string
  def custom_text(identifier, differential = nil)
    Rails.cache.fetch("#{identifier}-#{differential}") do
      custom_text = CustomText.find_by(
        identifier: identifier,
        differential: differential
      )

      custom_text.try(:content) || ''
    end
  end

  #
  # Renders a non-displayed error div warning of a data failure
  # Appears to have been intended to be used to provide error feedback on the studies
  # in app/views/studies/information/_items.html.erb but actual behaviour will result in the
  # error payload being placed in the div, but remaining invisible.
  # @todo Probably remove this and the references to it in app/views/studies/information/_items.html.erb
  #       Or possibly restore the intended behaviour in app/assets/javascripts/sequencescape/ajax_link_handling.js
  #
  # @param identifier [String] The id of the element
  def remote_error(identifier = 'remote_error')
    content_tag('div', id: identifier, class: 'error', style: 'display:none;') do
      'An error has occurred and the results can not be shown at the moment'
    end
  end

  # Inserts the icon used to indicate a field is required.
  # This will also be displayed on any <label> tags with the .required class
  # @return [String] HTML representing the required marker
  def required_marker
    icon('fas', 'asterisk', class: 'text-warning', title: 'required')
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

  # Renders a user guide with optional link. Applies appropriate styling
  #
  # @param display_text [String] The text of the user guide
  # @param link [String] Optional url to link the guide to.
  #
  # @return [type] [description]
  def display_user_guide(display_text, link = nil)
    alert(:user_guide) do
      concat link.present? ? link_to(display_text, link) : display_text
    end
  end

  def display_user_error(display_text, link = nil)
    alert(:danger) do
      link.present? ? link_to(display_text, link) : display_text
    end
  end

  #
  # Renders a badge containing the supplied text, with appropriate styling.
  # By default the 'badge-#!{status}' class is applied. These states are mapped to
  # bootstrap colours in components.scss (grep '// State-colour extensions')
  #
  # If you can't map the text directly to a style, such as if you are displaying a
  # number that you want to change its colours at certain thresholds, then you can
  # override the applied style with the style: argument.
  #
  # If the string passed in is empty, no badge will be rendered
  #
  # @example Render a request state badge.
  #   badge(request.state, type: 'request')
  # @example Render the size of a batch, which is red if too large.
  #   status = batch.size > MAX_SIZE ? 'danger' : 'success'
  #   badge(batch.size, type: 'batch-size', style: status )
  #
  # @param status [String] The text to display in the badge. Will also be used to set the style if not otherwise specified
  # @param type [String] Optional: Additional css-class applied to the badge (generic-badge by default)
  # @param style [String] Optional: Override the badge-* class otherwise set directly from the status.
  #
  # @return [type] HTML to render a badge
  def badge(status, type: 'generic-badge', style: status)
    return if status.blank?

    content_tag(:span, status, class: "#{type} badge badge-#{style}")
  end

  #
  # Used to add a counter to headers or links. Renders a blue badge containing the supplied number
  # Only supply a suffix if it can't be worked out from the context what is being counted.
  #
  # @param counter [Integer] The value to show in the badge
  # @param suffix [Integer, String] Optional: The type of thing being counted.
  # @return [String] HTML to render a badge
  def counter_badge(counter, suffix = '')
    status = suffix.present? ? pluralize(counter, suffix) : counter
    badge(status, type: 'counter-badge', style: 'primary')
  end

  def dynamic_link_to(summary_item)
    object = summary_item.object
    if object.instance_of?(Submission)
      return link_to("Submission #{object.id}", study_information_submission_path(object.study, object))
    elsif object.instance_of?(Receptacle)
      return link_to("#{object.label.capitalize} #{object.name}", receptacle_path(object))
    elsif object.instance_of?(Labware)
      return link_to("#{object.label.capitalize} #{object.name}", labware_path(object))
    elsif object.instance_of?(Request)
      return link_to("Request #{object.id}", request_path(object))
    else
      return 'No link available'
    end
  end

  def request_count_link(study, asset, state, request_type)
    matching_requests   = asset.requests.select { |request| (request.request_type_id == request_type.id) and request.state == state }
    html_options, count = { title: "#{asset.try(:human_barcode) || asset.id} #{state}" }, matching_requests.size

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

    if object.instance_of?(Receptacle)
      receptacle_path(object, options)
    elsif object.instance_of?(Labware)
      labware_path(object, options)
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

  ## From Pipelines

  def about(title = '')
    add :about, title
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

  # <li class="nav-item">
  #   <a class="nav-link <active>" id="name-tab" data-toggle="tab" href="#name"
  #    role="tab" aria-controls="name" aria-selected="true">name</a>
  # </li>
  def tab(name, target: nil, active: false, id: nil)
    target ||= name.parameterize
    active_class = active ? 'active' : ''
    id ||= "#{name}-tab".parameterize
    content_tag(:li, class: 'nav-item') do
      link_to name, "##{target}", id: id, data: { toggle: 'tab' }, role: 'tab', aria_controls: target, class: ['nav-link', active_class]
    end
  end

  # <div class="tab-pane fade show <active>" id="pending" role="tabpanel" aria-labelledby="peding-tab">
  #   yield
  # </div>
  def tab_pane(name, id: nil, tab_id: nil, active: false, &block)
    tab_id ||= "#{name}-tab".parameterize
    id ||= name.parameterize
    active_class = active ? 'active' : ''
    content_tag(:div, class: ['tab-pane', 'fade', 'show', active_class], id: id, role: 'tabpanel', aria_labelledby: tab_id, &block)
  end

  def item_status(item)
    if item.failures.empty?
      ''
    else
      '<span style="color:red;">FAILED</span>'
    end
  end

  def display_request_information(request, rit, batch = nil)
    r = request.value_for(rit.name, batch)
    r.presence || 'NA'
  end

  def display_boolean_results(result)
    return 'NA' if result.blank?
    if result == 'pass' || result == '1' || result == 'true'
      return icon('far', 'check-circle', title: result)
    else
      return icon('fas', 'exclamation-circle', class: 'text-danger', title: result)
    end
  end

  def sorted_requests_for_search(requests)
    sorted_requests = requests.select { |r| r.pipeline_id.nil? }
    new_requests = requests - sorted_requests
    new_requests.sort_by(&:pipeline_id)
    requests = requests + sorted_requests
  end

  # Creates a label that is hidden from the view so that testing is easier
  def hidden_label_tag_for_testing(name, text = nil, options = {})
    label_tag(name, text, options.merge(style: 'display:none;'))
  end

  def help_text(&block)
    content_tag(:small, class: 'form-text text-muted col', &block)
  end

  def help_link(text, entry = '', options = {})
    url = "#{configatron.help_link_base_url}/#{entry}"
    options[:class] = "#{options[:class]} external_help"
    link_to text, url, options
  end

  # The admin email address should be stored in config.yml for the current environment
  def help_email_link
    admin_address = configatron.admin_email || 'admin@test.com'
    link_to admin_address.to_s, "mailto:#{admin_address}"
  end
end
