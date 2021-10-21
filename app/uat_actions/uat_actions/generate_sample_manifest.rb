# frozen_string_literal: true

# Will construct a sample manifest
class UatActions::GenerateSampleManifest < UatActions
  self.title = 'Generate Sample Manifest'
  self.description = 'Generate sample manifest with the provided information.'
k
  form_field :study,
             :select,
             label: 'Study',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.first }

  form_field :supplier,
             :select,
             label: 'Supplier',
             help: 'The supplier under which samples originated.',
             select_options: -> { Supplier.active.alphabetical.first }

  form_field :asset_type,
             :text_field,
             label: 'Asset Type'

  form_field :count,
             :number_field,
             label: 'Count',
             help: 'The number of barcodes to generate',
             options: {
               minimum: 1,
               maximum: 96
             }

  def self.default
    new(study: UatActions::StaticRecords.study, supplier: UatActions::StaticRecords.supplier, asset_type: 'tube', count: 2)
  end

  def perform
    sample_manifest = SampleManifest.create!(study: study, supplier: supplier, asset_type: asset_type, count: count)
    sample_manifest.generate

    true
  end
end
