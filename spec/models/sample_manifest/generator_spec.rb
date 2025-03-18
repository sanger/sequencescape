# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifest::Generator, :sample_manifest, :sample_manifest_excel do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  before do
    allow(PlateBarcode).to receive(:create_barcode).and_return(
      build(:plate_barcode),
      build(:plate_barcode),
      build(:plate_barcode),
      build(:plate_barcode)
    )
  end

  let!(:user) { create(:user) }
  let!(:study) { create(:study) }
  let!(:supplier) { create(:supplier) }
  let!(:barcode_printer) { create(:barcode_printer) }
  let(:configuration) { SampleManifestExcel.configuration }
  let(:template) { 'plate_full' }

  let(:attributes) do
    { template: template, study_id: study.id, supplier_id: supplier.id, count: '4' }.with_indifferent_access
  end

  let(:column_updater_spy) { instance_double(SampleManifest::ColumnConditionalFormatUpdater) }

  after(:all) { SampleManifestExcel.reset! }

  it 'model name is sample manifest' do
    expect(described_class.model_name).to eq('SampleManifest')
  end

  it 'is not valid without a user' do
    expect(described_class.new(attributes, nil, configuration)).not_to be_valid
  end

  it 'is not valid unless all of the attributes are present' do
    SampleManifest::Generator::REQUIRED_ATTRIBUTES.each do |attribute|
      expect(described_class.new(attributes.except(attribute), user, configuration)).not_to be_valid
    end
  end

  it 'is not valid without configuration' do
    expect(described_class.new(attributes, user, nil)).not_to be_valid
  end

  it 'is not valid without columns' do
    expect(described_class.new(attributes.merge(template: 'dodgy_template'), user, configuration)).not_to be_valid
  end

  it 'will create a sample manifest' do
    generator = described_class.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.study_id).to eq(study.id)
    expect(generator.sample_manifest).not_to be_new_record
  end

  it 'raises an error if sample manifest is not valid' do
    expect { described_class.new(attributes.except(:study_id), user, configuration).execute }.to raise_error(
      ActiveRecord::RecordInvalid
    )
  end

  it 'generates sample manifest to create details_array' do
    generator = described_class.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.details_array).not_to be_empty
  end

  it 'xlsx file is generated and saved' do
    generator = described_class.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.generated).to be_truthy
  end

  it 'adds a password to the sample manifest' do
    generator = described_class.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.password).to be_present
  end

  it 'has an asset_type' do
    generator = described_class.new(attributes.merge(template: 'tube_full'), user, configuration)
    generator.execute
    expect(generator.sample_manifest.asset_type).to eq(configuration.manifest_types.find_by('tube_full').asset_type)
  end

  it 'calls ColumnConditionalFormatUpdater during sample manifest generation' do
    generator = described_class.new(attributes.merge(template: 'tube_full'), user, configuration)
    allow(column_updater_spy).to receive(:update_column_formatting_by_asset_type)
    allow(SampleManifest::ColumnConditionalFormatUpdater).to receive(:new).and_return(column_updater_spy)
    generator.execute

    expect(column_updater_spy).to have_received(:update_column_formatting_by_asset_type)
  end

  it 'prints labels if barcode printer is present' do
    allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])

    generator =
      described_class.new(
        attributes.merge(barcode_printer: barcode_printer.name, only_first_label: '0'),
        user,
        configuration
      )

    allow(RestClient).to receive(:post)
    expect(generator).to be_print_job_required
    generator.execute
    expect(generator.print_job_message).to be_key(:notice)
  end

  it 'print job is not valid with invalid printer name' do
    allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])

    generator =
      described_class.new(
        attributes.merge(barcode_printer: 'dodgy_printer', only_first_label: '0'),
        user,
        configuration
      )
    expect(generator).to be_print_job_required
    generator.execute
    expect(generator.print_job_message).to be_key(:error)
  end

  it 'does not have a print job if printer name has not been provided' do
    expect(described_class.new(attributes, user, configuration)).not_to be_print_job_required
  end

  context 'with rows_per_well set' do
    let(:template) { 'pools_plate' }

    it 'generates a details array with more than one entry per well' do
      generator = described_class.new(attributes, user, configuration)
      generator.execute
      expect(generator.sample_manifest.details_array.size).to eq(4 * 96 * 2)
    end
  end

  context 'with rows_per_well not set' do
    it 'generates a details array with one entry per well' do
      generator = described_class.new(attributes, user, configuration)
      generator.execute
      expect(generator.sample_manifest.details_array.size).to eq(4 * 96)
    end
  end
end
