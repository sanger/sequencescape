require 'rails_helper'

RSpec.describe "Acceptance", type: :model, sample_manifest_excel: true do

  let(:test_file) { 'test.xlsx' }

  attr_reader :download, :sample_manifest

  before(:each) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel', 'extract')
      config.load!
    end

    barcode = double('barcode')
    allow(barcode).to receive(:barcode).and_return(23)
    allow(PlateBarcode).to receive(:create).and_return(barcode)

    @sample_manifest = create :sample_manifest, rapid_generation: true
    sample_manifest.generate

    @download = SampleManifestExcel::Download.new(sample_manifest,
        SampleManifestExcel.configuration.columns.test.dup,
        SampleManifestExcel.configuration.ranges.dup)
    download.save(test_file)
  end

  it 'creates a worksheet' do
    assert File.file?(test_file)
    assert download.password
  end

  after(:each) do
    SampleManifestExcel.reset!
    File.delete(test_file) if File.exist?(test_file)
  end
end