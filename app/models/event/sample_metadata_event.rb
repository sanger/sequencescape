# frozen_string_literal: true
class Event::SampleMetadataEvent < Event
  # Indicates that the metadata associated with a sample has been updated.
  # Usage example:
  #   sample.events.updated_sample_metadata!(changed_attributes, user)
  def self.updated_sample_metadata!(changed_attributes, user)
    return if changed_attributes.empty?

    message = 'Updated sample metadata'
    content = changed_attributes.map { |field, (before, after)| "#{field}: #{before} -> #{after}" }.join('; ')

    create!(
      eventful: sample_now,
      message: message,
      content: content,
      family: 'sample_metadata',
      of_interest_to: 'administrators',
      created_by: user&.login
    )
  end
end
