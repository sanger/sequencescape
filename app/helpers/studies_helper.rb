# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015,2016 Genome Research Ltd.

module StudiesHelper
  def status_link_title
    if @study.inactive? || @study.pending?
     'Open'
    else
     'Close'
    end
  end

  def display_owner(study)
    owners_for_display([study.owner].compact)
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
    content_tag(:span, study.state, class: "study-state label label-#{bootstrapify_study_state(study.state)}")
    link_to(link_text, study_path(study), options)
  end
end
