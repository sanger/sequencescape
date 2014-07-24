class Event::SampleManifestEvent< Event
  def self.created_sample!(sample, user)
    self.create!(
      :eventful => sample,
      :message => 'Created by Sample Manifest',
      :content => Date.today.to_s,
      :family => 'created_sample_using_sample_manifest',
      :created_by => user ? user.login : nil
    )
  end

  def self.updated_sample!(sample, user)
    self.create!(
      :eventful => sample,
      :message => 'Updated by Sample Manifest',
      :content => Date.today.to_s,
      :family => 'updated_sample_using_sample_manifest',
      :created_by => user ? user.login : nil
    )
  end
end
