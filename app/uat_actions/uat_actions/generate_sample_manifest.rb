# frozen_string_literal: true

# Will construct a sample manifest
class UatActions::GenerateSampleManifest < UatActions
  self.title = 'Generate sample manifest'
  self.description = 'Generate sample manifest with the provided information.'
  self.category = :generating_samples

  include UatActions::Shared::StudyHelper
  include UatActions::Shared::SupplierHelper

  ERROR_TUBE_PURPOSE_DOES_NOT_EXIST = "Tube purpose '%s' does not exist."

  form_field :study_name,
             :select,
             label: 'Study Name',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }

  form_field :supplier_name,
             :select,
             label: 'Supplier Name',
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

  form_field :tube_purpose_name,
             :select,
             label: 'Tube Purpose',
             help: 'Select the tube purpose to create',
             select_options: -> { Tube::Purpose.alphabetical.pluck(:name) }

  form_field :with_samples, :check_box, help: 'Create new samples for recipients?', label: 'With Samples?'

  validates :tube_purpose_name, presence: true
  validate :validate_tube_purpose_exists

  def self.default
    new(
      study_name: UatActions::StaticRecords.study.name,
      supplier_name: UatActions::StaticRecords.supplier.name,
      asset_type: '1dtube',
      count: 2,
      tube_purpose_name: UatActions::StaticRecords.tube_purpose.name
    )
  end

  def perform
    sample_manifest = create_sample_manifest
    generate_manifest(sample_manifest)
    print_report(sample_manifest)

    true
  end

  # Validates that the tube purpose exists for the selected tube purpose name.
  #
  # @return [void]
  def validate_tube_purpose_exists
    return if tube_purpose_name.blank? # Already validated by presence
    return if Tube::Purpose.exists?(name: tube_purpose_name)

    message = format(ERROR_TUBE_PURPOSE_DOES_NOT_EXIST, tube_purpose_name)
    errors.add(:tube_purpose_name, message)
  end

  def create_sample_manifest
    SampleManifest.create!(study:, supplier:, asset_type:, count:, purpose:)
  end

  def generate_manifest(sample_manifest)
    sample_manifest.generate
    create_samples(sample_manifest) if with_samples == '1'
  end

  def create_samples(sample_manifest)
    sample_manifest.assets.each do |asset|
      raise 'Manifest for plates is not supported yet' unless asset_type == '1dtube'

      create_sample("Sample_#{asset.human_barcode}_1", sample_manifest).tap do |sample|
        asset.aliquots.create!(sample:, study:)
        study.samples << sample
      end
    end
  end

  private

  # Validates that the plate purpose exists for the selected plate purpose name.
  #
  # @return [void]
  def validate_plate_purpose_exists
    return if plate_purpose_name.blank?
    return if PlatePurpose.exists?(name: plate_purpose_name)

    message = format(ERROR_PLATE_PURPOSE_DOES_NOT_EXIST, plate_purpose_name)
    errors.add(:plate_purpose_name, message)
  end

  def purpose
    Purpose.find_by!(name: tube_purpose_name)
  end

  def create_sample(sample_name, sample_manifest)
    Sample.create!(
      name: sample_name,
      sanger_sample_id: sample_name,
      sample_metadata_attributes: {
        supplier_name: sample_name,
        collected_by: UatActions::StaticRecords.collection_site,
        donor_id: "#{sample_name}_donor",
        sample_common_name: 'human'
      },
      sample_manifest: sample_manifest
    )
  end

  def print_report(sample_manifest)
    report['manifest'] = sample_manifest.id

    sample_manifest.barcodes.each_with_index { |barcode, index| report["tube_#{index}"] = barcode }
  end
end
