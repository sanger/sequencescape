# frozen_string_literal: true
class Event::SampleManifestEvent < Event
  def self.created_using_sample_manifest!(eventful, sample_manifest, user)
    create!(
      eventful: eventful,
      message: 'Created by Sample Manifest',
      content: sample_manifest.name,
      family: 'created_sample_using_sample_manifest',
      created_by: user&.login
    )
  end

  def self.updated_using_sample_manifest!(eventful, sample_manifest, user)
    create!(
      eventful: eventful,
      message: 'Updated by Sample Manifest',
      content: sample_manifest.name,
      family: 'updated_sample_using_sample_manifest',
      created_by: user&.login
    )
  end
end
