SampleManifestUploadProcessingJob = Struct.new(:upload, :tag_group) do
  def perform
    upload.process(tag_group)
    upload.processed?
  end
end
