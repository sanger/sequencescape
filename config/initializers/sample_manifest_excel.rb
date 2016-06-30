require File.join(Rails.root, "lib", "sample_manifest_excel", "sample_manifest_excel")

SampleManifestExcel.configure do |config|
  config.folder = File.join("config", "sample_manifest_excel")
  config.load!
end