# frozen_string_literal: true
module StudiesHelper
  def status_link_title(study)
    study.inactive? || study.pending? ? 'Open' : 'Close'
  end

  def display_owners(study)
    owners_for_display(study.owners)
  end

  # Returns a styled badge for the given data release strategy.
  # The badge is generally a saturated colour with white text.
  def strategy_badge(strategy_text)
    # Saturated Bootstrap 5 colours from https://getbootstrap.com/docs/5.2/customize/color/#all-colors
    strategy_colours = [
      '#0d6efd', # blue
      '#fd7e14', # orange
      '#343a40'  # gray-800
    ]

    strategy_index = Study::DATA_RELEASE_STRATEGIES.index(strategy_text)
    strategy_colour = strategy_colours[strategy_index] || '#000000' # default to black if not found

    css_style = "background-color: #{strategy_colour}; color: #ffffff;"
    badge(strategy_text.humanize, type: 'data-release-strategy', css_style: css_style)
  end

  # Returns a styled badge for the given data release timing.
  # The badge is generally a pastel colour with black text.
  def timing_badge(timing_text)
    # Pastel Bootstrap 5 colours from https://getbootstrap.com/docs/5.2/customize/color/#all-colors
    timing_colours = [
      '#e0cffc', # indigo-100
      '#f7d6e6', # pink-100
      '#ffe69c', # yellow-200
      '#e9ecef', # gray-200
      '#9eeaf9'  # cyan-200
    ]

    all_timings = Study::DATA_RELEASE_TIMINGS +
      [Study::DATA_RELEASE_TIMING_NEVER, Study::DATA_RELEASE_TIMING_PUBLICATION]

    timing_index = all_timings.index(timing_text)
    timing_colour = timing_colours[timing_index] || '#ffffff' # default to white if not found

    css_style = "background-color: #{timing_colour}; color: #000000;"
    badge(timing_text.humanize, type: 'data-release-timing', css_style: css_style)
  end

  def display_file_icon(document) # rubocop:todo Metrics/MethodLength
    return icon('fas', 'exclamation-circle', class: 'text-danger') unless document

    case document.content_type
    when /pdf/
      icon('far', 'file-pdf', title: 'PDF')
    when /word/
      icon('far', 'file-word', title: 'Word')
    when /excel/
      icon('far', 'file-excel', title: 'Excel')
    else
      icon('far', 'file-alt')
    end
  end

  def label_asset_state(asset)
    asset.closed? ? 'closed' : 'open'
  end

  def study_link(study, options)
    link_text = tag.strong(study.name) << ' ' << badge(study.state, type: 'study-state')
    link_to(link_text, study_path(study), options)
  end

  private

  def owners_for_display(owners)
    owners.empty? ? 'Not available' : owners.map(&:name).join(', ')
  end
end
