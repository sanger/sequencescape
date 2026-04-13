# frozen_string_literal: true
module HistoriesHelper
  UNSPECIFIED_VALUE = '<span class="unspecified">Not specified</span>'.html_safe.freeze

  # Given a json hash of attribute changes, renders a human-readable description of the changes.
  # Example input:
  # {
  #   "name": ["Old Name", "New Name"],
  #   "description": [null, "New Description"],
  #   "removed_key": ["Old Key", null]
  # }
  # Example output:
  # name: 'Old Name' -> 'New Name'<br/>
  # description: '' -> 'New Description'<br/>
  # removed_key: 'Old Key' -> ''
  def render_diff_event_content(content)
    changes = JSON.parse(content)
    changes.map do |attribute, (old_value, new_value)|
      old_value = UNSPECIFIED_VALUE if old_value.nil?
      new_value = UNSPECIFIED_VALUE if new_value.nil?
      "#{h(attribute.humanize)}:&emsp; #{h(old_value)} &rarr; #{h(new_value)}"
    end.join('<br/>').html_safe # rubocop:disable Rails/OutputSafety
  rescue StandardError
    # if content is not a valid JSON string, return it as is
    h(content)
  end
end
