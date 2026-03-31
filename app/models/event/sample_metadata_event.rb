# frozen_string_literal: true
class Event::SampleMetadataEvent < Event
  # Indicates that the metadata associated with a sample has been updated.
  # Usage example:
  #   sample.events.updated_sample_metadata!(attribute_changes, user)
  def self.updated_sample_metadata!(sample, attribute_changes, user)
    return if attribute_changes.empty?

    message = 'Updated sample metadata'
    content = attribute_changes.to_json

    create!(
      eventful: sample,
      message: message,
      content: content,
      family: 'sample_metadata',
      of_interest_to: 'administrators',
      created_by: user&.login
    )
  end

  def to_partial_path
    'events/diff_event'
  end
end
