# frozen_string_literal: true

# Groups together tools for deprecating areas of the interface
module DeprecationHelper
  WarningLevel = Struct.new(:style, :title, :icon)

  # Contains the stylings which will be applied to the deprecation warning
  # candidate: We haven't set a date for deprecation yet
  # scheduled: A date has been set, but its more than a week away.
  # imminent: Deprecation is less than a week away
  LEVELS = {
    candidate: WarningLevel.new('info', 'Request for feedback', 'info-circle').freeze,
    scheduled: WarningLevel.new('warning', 'Scheduled for removal in %s days', 'exclamation-circle').freeze,
    imminent: WarningLevel.new('danger', 'Scheduled for removal in %s days', 'exclamation-triangle').freeze
  }.freeze

  # The threshold at which to switch to imminent styling
  IMMINENT_THRESHOLD = 7

  #
  # Renders a card surrounding the enclosed block which informs the user of upcoming deprecation.
  # The user will be presented with a button to let us know they still need the feature, and a
  # link to the alternative if provided. The warning will become increasingly prominent as
  # the date approaches.
  #
  # Once date has been reached, the section will be automatically hidden. It will also log
  # every-time it gets hit to allow for removal.
  #
  # @example sample_registration.html.erb
  #  <%= deprecate_section(
  #     date: Date.parse('20190708'),
  #     message: 'Sample registration has been replaced by sample manifests. These provide added features',
  #     replaced_by: sample_manifest_path) do %>
  #     <p>Old we content</p>
  #  <% end %>
  # @param date [nil,Date] The date at which the section will be hidden.
  # @param message [String] Body explaining why the feature is being removed, and where the functionality can be found elsewhere.
  # @param replaced_by [String,nil] URL of the replacement (if applicable).
  # @param custom_title [String] Override the title determined by the level.
  # @param custom_style [String] Overide the styles determined by the level.
  # @yield [Void] Yield to block rendering the contents of the card (ie. the feature to be deprecated)
  #
  # @return [String] The HTML to render
  def deprecate_section(date: nil, message: '', replaced_by: nil, custom_title: nil, custom_style: nil, &block)
    # If we're past the date just hide the section
    if date && Date.current > date
      Rails.logger.warn "Deprecated section past deadline: #{Kernel.caller.first}"
      return ''
    end

    level = _deprecation_level(date)
    remaining = date && (date - Date.current).to_i
    title = (custom_title || level.title) % remaining
    style = custom_style || level.style

    content_tag(:div, class: ['card', "border-#{style}", 'mb-3']) do
      concat(content_tag(:div, class: ['card-body', "bg-#{style}", 'text-white']) do
        concat icon('fas', level.icon, title)
        concat content_tag(:p, message)
        concat link_to 'See the alternative', replaced_by, class: %w[btn btn-block btn-outline-light] if replaced_by
        concat mail_to configatron.admin_email, icon('far', 'envelope ', 'Let us know if you still need this'), class: %w[btn btn-block btn-outline-light]
      end)
      concat content_tag(:div, class: 'card-body', &block)
    end
  end

  def _deprecation_level(date)
    if date.nil? then LEVELS[:candidate]
    elsif (date - Date.current) < IMMINENT_THRESHOLD then LEVELS[:imminent]
    else
      LEVELS[:scheduled]
    end
  end
end
