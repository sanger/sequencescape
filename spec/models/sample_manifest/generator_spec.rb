# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifest::Generator, type: :model, sample_manifest_excel: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  before(:each) do
    barcode = double('barcode')
    allow(barcode).to receive(:barcode).and_return(23)
    allow(PlateBarcode).to receive(:create).and_return(barcode)
  end

  let!(:user)             { create(:user) }
  let!(:study)            { create(:study) }
  let!(:supplier)         { create(:supplier) }
  let!(:barcode_printer)  { create(:barcode_printer) }
  let(:configuration)     { SampleManifestExcel.configuration }

  let(:attributes) do
    { "template": 'plate_full', "study_id": study.id, "supplier_id": supplier.id,
      "count": '4' }.with_indifferent_access
  end

  it 'model name is sample manifest' do
    expect(SampleManifest::Generator.model_name).to eq('SampleManifest')
  end

  it 'is not valid without a user' do
    expect(SampleManifest::Generator.new(attributes, nil, configuration)).to_not be_valid
  end

  it 'is not be unless all of the attributes are present' do
    SampleManifest::Generator::REQUIRED_ATTRIBUTES.each do |attribute|
      expect(SampleManifest::Generator.new(attributes.except(attribute), user, configuration)).to_not be_valid
    end
  end

  it 'is not valid without configuration' do
    expect(SampleManifest::Generator.new(attributes, user, nil)).to_not be_valid
  end

  it 'is not valid without columns' do
    expect(SampleManifest::Generator.new(attributes.merge(template: 'dodgy_template'), user, configuration)).to_not be_valid
  end

  it 'will create a sample manifest' do
    generator = SampleManifest::Generator.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.study_id).to eq(study.id)
    expect(generator.sample_manifest).to_not be_new_record
  end

  it 'raises an error if sample manifest is not valid' do
    expect { SampleManifest::Generator.new(attributes.except(:study_id), user, configuration).execute }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'generates sample manifest to create details_array' do
    generator = SampleManifest::Generator.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.details_array).to_not be_empty
  end

  it 'xlsx file is generated and saved' do
    generator = SampleManifest::Generator.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.generated).to be_truthy
  end

  it 'adds a password to the sample manifest' do
    generator = SampleManifest::Generator.new(attributes, user, configuration)
    generator.execute
    expect(generator.sample_manifest.password).to be_present
  end

  it 'has an asset_type' do
    generator = SampleManifest::Generator.new(attributes.merge(template: 'tube_full'), user, configuration)
    generator.execute
    expect(generator.sample_manifest.asset_type).to eq(configuration.manifest_types.find_by('tube_full').asset_type)
  end

  it 'prints labels if barcode printer is present' do
    allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])

    generator = SampleManifest::Generator.new(attributes.merge(barcode_printer: barcode_printer.name,
                                                               only_first_label: '0'), user, configuration)

    allow(RestClient).to receive(:post)
    expect(generator).to be_print_job_required
    generator.execute
    expect(generator.print_job_message.key?(:notice)).to be_truthy
  end

  it 'print job is not valid with invalid printer name' do
    allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])

    generator = SampleManifest::Generator.new(attributes.merge(barcode_printer: 'dodgy_printer',
                                                               only_first_label: '0'), user, configuration)
    expect(generator).to be_print_job_required
    generator.execute
    expect(generator.print_job_message.key?(:error)).to be_truthy
  end

  it 'does not have a print job if printer name has not been provided' do
    expect(SampleManifest::Generator.new(attributes, user, configuration)).to_not be_print_job_required
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
