class ::Io::ModelExtensions::SampleManifest::SampleMapper
  def self.as_json(options = {})
    options.delete(:object).as_json(options)
  end
end
