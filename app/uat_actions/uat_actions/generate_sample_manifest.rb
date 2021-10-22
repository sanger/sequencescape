# frozen_string_literal: true

# Will construct a sample manifest
class UatActions::GenerateSampleManifest < UatActions
  self.title = 'Generate sample manifest'
  self.description = 'Generate sample manifest with the provided information.'

  form_field :study,
             :select,
             label: 'Study',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }

  form_field :supplier,
             :select,
             label: 'Supplier',
             help: 'The supplier under which samples originated.',
             select_options: -> { Supplier.alphabetical.pluck(:name) }

  form_field :asset_type,
             :select,
             label: 'Asset Type',
             help: 'Type of asset to generate for the manifest',
             select_options: -> { SampleManifest::CoreBehaviour::BEHAVIOURS }

  form_field :count,
             :number_field,
             label: 'Count',
             help: 'The number of barcodes to generate',
             options: {
               minimum: 1,
               maximum: 96
             }

  form_field :with_samples, :check_box, help: 'Create new samples for recipients?', label: 'With Samples?'

  def self.default
    new(
      study: UatActions::StaticRecords.study,
      supplier: UatActions::StaticRecords.supplier,
      asset_type: '1dtube',
      count: 2
    )
  end

  def generate_sample_for_receptacle(asset, _sample_params)
    asset.aliquots.create!
  end

  def create_sample(sample_name, study)
    Sample.create!(name: sample_name, studies: [study], sample_metadata_attributes: { supplier_name: sample_name })
  end

  def create_samples_for_asset(asset, asset_type, study)
    raise 'Manifest for plates is not supported yet' unless asset_type == '1dtube'
    sample = create_sample("Sample_#{asset.human_barcode}_1", study)
    asset.aliquots.create!(sample: sample)
  end

  def print_report
    report['manifest'] = sample_manifest.id
    sample_manifest.assets.each_with_index do |asset, pos|
      create_samples_for_asset(asset, asset_type, UatActions::StaticRecords.study) if with_samples == '1'
      report["asset_#{pos}"] = asset.human_barcode
    end
  end

  def perform
    sample_manifest =
      SampleManifest.create!(
        study: UatActions::StaticRecords.study,
        supplier: UatActions::StaticRecords.supplier,
        asset_type: asset_type,
        count: count
      )
    sample_manifest.generate
    print_report

    true
  end
end
