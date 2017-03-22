# Processes the uploaded manifest
SampleManifest::ProcessJob = Struct.new(:sample_manifest_id, :user_id, :override_sample_information) do
  def perform
    sample_manifest.process_job(user, override_sample_information)
  end

  def sample_manifest
    SampleManifest.find(sample_manifest_id)
  end

  def user
    User.find(user_id)
  end
end
