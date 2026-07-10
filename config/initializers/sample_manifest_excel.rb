# frozen_string_literal: true

# Run on boot, but do not run again on reload
Rails.application.config.after_initialize do
  unless Rails.env.test?
    SampleManifestExcel.configure do |config|
      config.folder = File.join('config', 'sample_manifest_excel')
      config.tag_group = 'Magic Tag Group'
      config.load!
    end
  end
end
