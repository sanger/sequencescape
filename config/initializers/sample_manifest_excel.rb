# frozen_string_literal: true
require File.join(Rails.root, 'app', 'sample_manifest_excel', 'sample_manifest_excel')

unless Rails.env.test?
  SampleManifestExcel.configure do |config|
    config.folder = File.join('config', 'sample_manifest_excel')
    config.tag_group = 'Magic Tag Group'
    config.load!
  end
end
