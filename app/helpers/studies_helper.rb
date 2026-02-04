# frozen_string_literal: true
module StudiesHelper
  def status_link_title(study)
    study.inactive? || study.pending? ? 'Open' : 'Close'
  end

  def display_owners(study)
    owners_for_display(study.owners)
  end

  private

  def owners_for_display(owners)
    owners.empty? ? 'Not available' : owners.map(&:name).join(', ')
  end

  public

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

  def good_icon
    icon('fas', 'check', class: 'text-success')
  end

  def bad_icon
    icon('fas', 'xmark', class: 'text-danger')
  end

  def checklist_fallback_link(text, path)
    "Please contact a #{link_to(text, path)}".html_safe # rubocop:disable Rails/OutputSafety
  end

  def checklist_item(condition:, good:, bad:, action: nil, action_permission: nil, fallback: nil) # rubocop:disable Metrics/ParameterLists
    content_tag(:div) do
      if condition
        safe_join([good_icon, ' ', good])
      else
        safe_join(
          [
            bad_icon,
            ' ',
            bad,
            content_tag(:span, class: 'text-muted') do
              safe_join(
                [
                  ' — ',
                  (action if action && (action_permission.nil? || action_permission)),
                  (fallback if fallback && (action_permission == false))
                ]
              )
            end
          ]
        )
      end
    end
  end
end
