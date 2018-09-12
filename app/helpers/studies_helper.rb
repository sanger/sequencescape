
module StudiesHelper
  def status_link_title
    if @study.inactive? || @study.pending?
      'Open'
    else
      'Close'
    end
  end

  def display_owners(study)
    owners_for_display(study.owners)
  end

  private

  def owners_for_display(owners)
    owners.empty? ? 'Not available' : owners.map(&:name).join(', ')
  end

  public

  def display_file_icon(document)
    return image_tag('error.png') unless document
    case document.content_type
    when /pdf/
      image_tag('pdf_icon.png', size: '18x18')
    when /word/
      image_tag('word_icon.png')
    when /excel/
      image_tag('excel_icon.png')
    else
      image_tag('plaintext_icon.png')
    end
  end

  def label_asset_state(asset)
    asset.closed? ? 'closed' : 'open'
  end

  def study_link(study, options)
    link_text = content_tag(:strong, study.name) << ' ' <<
                content_tag(:span, study.state, class: "study-state badge badge-#{study.state}")
    link_to(link_text, study_path(study), options)
  end
end
