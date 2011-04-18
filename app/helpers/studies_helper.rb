module StudiesHelper
  def status_link_title
    if @study.inactive? || @study.pending?
     "Open"
    else
     "Close"
    end
  end

  def display_owner(study)
    owners_for_display([ study.owner ].compact)
  end

  def display_owners(study)
    owners = study.roles.map { |role| role.name == 'owner' ? role.users : nil }.compact
    owners_for_display(owners.flatten)
  end

private

  def owners_for_display(owners)
    owners.empty? ? 'Not available' : owners.map(&:name).join(', ')
  end

public

  def display_file_icon(document)
    return image_tag("error.png") unless document
    case document.content_type
    when /pdf/
      image_tag("pdf_icon.png", :size => "18x18")
    when /word/
      image_tag("word_icon.png")
    when /excel/
      image_tag("excel_icon.png")
    else
      image_tag("plaintext_icon.png")
    end
  end

  def label_asset_state(asset)
    asset.closed? ? "closed" : "open"
  end
end
