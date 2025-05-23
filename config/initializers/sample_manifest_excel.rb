# frozen_string_literal: true

Rails.application.config.after_initialize do
  unless Rails.env.test?
    SampleManifestExcel.configure do |config|
      config.folder = File.join('config', 'sample_manifest_excel')
      config.tag_group = 'Magic Tag Group'
      config.load!
    end
  end
end

Rails.application.config.tube_manifest_barcode_config = {
  barcode_type_labels: {
    '1d' => '1D Barcode (with machine readable barcode encoded)',
    '2d' => '2D Barcode (with human readable barcode encoded)'
  },
  two_dimensional_label_template: 'traction_tube_label_template'
}
