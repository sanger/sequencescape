# frozen_string_literal: true
# rubocop:todo Metrics/ModuleLength
module ApplicationHelper
  include ControllerHelper

  # Should return either the custom text or a blank string
  def custom_text(identifier, differential = nil)
    Rails
      .cache
      .fetch("#{identifier}-#{differential}") do
        custom_text = CustomText.find_by(identifier:, differential:)

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
    tag.div(id: identifier, class: 'error', style: 'display:none;') do
      'An error has occurred and the results can not be shown at the moment'
    end
  end

  # Inserts the icon used to indicate a field is required.
  # This will also be displayed on any <label> tags with the .required class
  # @return [String] HTML representing the required marker
  def required_marker
    icon('fas', 'asterisk', class: 'text-warning', title: 'required')
  end

  # Returns the appropriate icon suffix for the current environment
  # Returns empty string for production
  # Returns "-#{environment}" for training, staging
  # Returns "-development" for any other environment
  # @return [String] The suffix to append to the icon name
  def icon_suffix
    environment = Rails.env
    case environment
    when 'production'
      ''
    when 'training', 'staging'
      "-#{environment}"
    else
      '-development'
    end
  end

  # Return the appropriate Sequencescape logo for the current environment
  # @return [String] The path to the logo image
  def sequencescape_logo
    "images/logo-gradient#{icon_suffix}.svg"
  end

  # Return the appropriate favicon for the current environment
  # @return [String] The path to the favicon
  def favicon
    "favicon#{icon_suffix}.ico"
  end

  # Return the appropriate apple icon for the current environment
  # @return [String] The path to the apple icon
  def apple_icon
    "apple-icon#{icon_suffix}.png"
  end

  def render_flashes
    flash.each { |key, message| concat(alert(key, id: "message_#{key}") { render_message(message) }) }
    nil
  end

  # A helper method for render_flashes - If multiple messages, render them as a list, else render as a single div
  # @param messages [Array<String>, String] The flash message or messages to be rendered
  def render_message(messages)
    messages = Array(messages)
    if messages.size > 1
      tag.ul { messages.each { |m| concat tag.li(m) } }
    else
      tag.div(messages.first)
    end
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
    alert(:user_guide) { concat link.present? ? link_to(display_text, link) : display_text }
  end

  def display_user_error(display_text, link = nil)
    alert(:danger) { link.present? ? link_to(display_text, link) : display_text }
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
  # @param status [String] The text to display in the badge. Will also be used to set the style if not otherwise
  #                        specified
  # @param type [String] Optional: Additional css-class applied to the badge (generic-badge by default)
  # @param style [String] Optional: Override the badge-* class otherwise set directly from the status.
  # @param css_style [String] Optional: Additional css styles to apply to the badge
  #
  # @return [type] HTML to render a badge
  def badge(status, type: 'generic-badge', style: status, css_style: '')
    return if status.blank?

    tag.span(status, class: "#{type} badge badge-#{style}", style: css_style)
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

  # rubocop:todo Metrics/MethodLength
  def dynamic_link_to(summary_item) # rubocop:todo Metrics/AbcSize
    object = summary_item.object
    if object.instance_of?(Submission)
      link_to("Submission #{object.id}", study_information_submission_path(object.study, object))
    elsif object.instance_of?(Receptacle)
      link_to("#{object.label.capitalize} #{object.name}", receptacle_path(object))
    elsif object.instance_of?(Labware)
      link_to("#{object.label.capitalize} #{object.name}", labware_path(object))
    elsif object.instance_of?(Request)
      link_to("Request #{object.id}", request_path(object))
    else
      'No link available'
    end
  end

  # rubocop:enable Metrics/MethodLength

  def request_count_link(study, asset, state, request_type) # rubocop:todo Metrics/AbcSize
    matching_requests =
      asset.requests.select { |request| (request.request_type_id == request_type.id) and request.state == state }
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

  # rubocop:todo Metrics/ParameterLists
  def request_link(object, count, request_type, status = nil, options = {}, link_options = {})
    # rubocop:enable Metrics/ParameterLists
    link_to_if(count != 0, count, request_list_path(object, request_type, status, options), link_options)
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
    user.follower_of?(item) ? "Unfollow #{msg}" : "Follow #{msg}"
  end

  ## From Pipelines

  def about(title = '')
    add :about, title
  end

  def tabulated_error_messages_for(*params) # rubocop:todo Metrics/AbcSize
    options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
    objects = params.filter_map { |object_name| instance_variable_get(:"@#{object_name}") }
    count = objects.inject(0) { |sum, object| sum + object.errors.count }
    if count.zero?
      ''
    else
      error_messages = objects.map { |object| object.errors.full_messages.map { |msg| tag.div(msg) } }.join
      [
        tag.td(class: 'error item') { "Your #{params.first} has not been created." },
        tag.td(class: 'error') { raw(error_messages) }
      ].join.html_safe
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
    tag.li(class: 'nav-item') do
      link_to name,
              "##{target}",
              id: id,
              data: {
                toggle: 'tab'
              },
              role: 'tab',
              aria_controls: target,
              class: ['nav-link', active_class]
    end
  end

  # <div class="tab-pane fade show <active>" id="pending" role="tabpanel" aria-labelledby="peding-tab">
  #   yield
  # </div>
  def tab_pane(name, id: nil, tab_id: nil, active: false, &)
    tab_id ||= "#{name}-tab".parameterize
    id ||= name.parameterize
    active_class = active ? 'active' : ''
    tag.div(class: ['tab-pane', 'fade', 'show', active_class], id: id, role: 'tabpanel', aria_labelledby: tab_id, &)
  end

  def display_boolean_results(result)
    return 'NA' if result.blank?

    if %w[pass 1 true].include?(result)
      icon('far', 'check-circle', title: result)
    else
      icon('fas', 'exclamation-circle', class: 'text-danger', title: result)
    end
  end

  def sorted_requests_for_search(requests)
    sorted_requests = requests.select { |r| r.pipeline_id.nil? }
    new_requests = requests - sorted_requests
    new_requests.sort_by(&:pipeline_id)
    requests += sorted_requests
  end

  # Creates a label that is hidden from the view so that testing is easier
  def hidden_label_tag_for_testing(name, text = nil, options = {})
    label_tag(name, text, options.merge(style: 'display:none;'))
  end

  def help_text(&)
    tag.small(class: 'form-text text-muted col', &)
  end

  def help_link(text, entry = '', options = {})
    url = "#{configatron.help_link_base_url}/#{entry}"
    options[:class] = "#{options[:class]} external_help"
    link_to text, url, options
  end

  def fresh_sevice_link
    link_to 'FreshService', configatron.fresh_sevice_new_ticket_url
  end

  #
  # Handles rendering of JSON to a series of nested lists. Does the following:
  # String: Rendered as-is
  # Array: Unordered list (Strictly speaking arrays are ordered, but we probably don't care.)
  # Object: Descriptive list
  # Other: Calls to_s
  # Processes each in turn and called recursively
  #
  # @param [Hash, String, Array,, #to_s] json The Object to render
  #
  # @return [String] HTML formatted for rendering
  #
  # rubocop:todo Metrics/MethodLength
  def render_parsed_json(json) # rubocop:todo Metrics/AbcSize
    case json
    when String
      json
    when Array
      tag.ul { json.each { |elem| concat tag.li(render_parsed_json(elem)) } }
    when Hash
      tag.dl do
        json.each do |key, value|
          # Strictly speaking json should only have strings as keys. But the same constraint doesn't apply to hashes,
          # so we're a little more permissive here for flexibilities sake
          concat tag.dt(render_parsed_json(key))
          concat tag.dd(render_parsed_json(value))
        end
      end
    else
      json.to_s
    end
  end

  # rubocop:enable Metrics/MethodLength

  #
  # Ideally we don't want inline script tags, however there is a fair chunk of
  # legacy code, some of which isn't trivial to migrate, as it uses erb to
  # generate javascript, rather than using data-attributes.
  #
  # This tag:
  # - Ensures we add a nonce for security
  # - If the page is still loading,
  #   delays script execution until DOMContentLoaded to ensure that the
  #   modern JS has had a chance to export jQuery
  # - If the page has already loaded, executes the script immediately.
  #   This is needed for use cases where the partial that renders this script
  #   is loaded after the main page has loaded
  #   e.g. the admin study edit page, within the admin study index page.
  #
  # @return [String] Script tag
  #
  def legacy_javascript_tag
    javascript_tag nonce: true do
      concat 'if (document.readyState === "loading") {window.addEventListener("DOMContentLoaded", function() {'.html_safe # rubocop:disable Layout/LineLength
      yield
      concat '});} else {'.html_safe
      yield
      concat '}'.html_safe
    end
  end
end
# rubocop:enable Metrics/ModuleLength

# error_messages_for method was deprecated, however lots of the tests depend on the message format it
# was using.
# <https://apidock.com/rails/ActionView/Helpers/ActiveRecordHelper/error_messages_for>
def render_error_messages(object)
  return if object.errors.count.zero?

  contents = +''
  contents << error_message_header(object)
  contents << error_messages_ul_html_safe(object)
  content_tag(:div, contents.html_safe)
end

def error_message_header(object)
  count = object.errors.full_messages.count
  model_name = object.class.to_s.tableize.tr('_', ' ').gsub(%r{/.*}, '').singularize
  is_plural = count > 1 ? 's' : ''
  header = "#{count} error#{is_plural} prohibited this #{model_name} from being saved"
  content_tag(:h2, header)
end

def error_messages_ul_html_safe(object)
  messages = object.errors.full_messages.map { |msg| content_tag(:li, ERB::Util.html_escape(msg)) }.join.html_safe
  content_tag(:ul, messages)
end
