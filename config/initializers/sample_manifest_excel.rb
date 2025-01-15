# frozen_string_literal: true

Rails.application.config.to_prepare do
  unless Rails.env.test?
    SampleManifestExcel.configure do |config|
      config.folder = File.join('config', 'sample_manifest_excel')
      config.tag_group = 'Magic Tag Group'
      config.load!
    end
  end
end
