require File.join(Rails.root, 'lib', 'sample_manifest_excel', 'sample_manifest_excel')

unless Rails.env.test?
  SampleManifestExcel.configure do |config|
    config.folder = File.join('config', 'sample_manifest_excel')
    config.load!
  end
end
