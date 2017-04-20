require 'rails_helper'

RSpec.describe SampleManifestExcel::TestDownload, type: :model, sample_manifest_excel: true do
  attr_reader :spreadsheet

  let(:test_file) { 'test.xlsx' }
  let(:download) {
    SampleManifestExcel::TestDownload.new(
                                                        columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
                                                        data: {}, no_of_rows: 5, study: 'WTCCC', supplier: 'Test supplier',
                                                        count: 1, type: 'Tubes'
                                                        )
  }

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  it 'should create a file' do
    expect(File.file?(test_file))
  end

  it 'should create a worksheet with some data' do
    expect(download.worksheet.columns.count).to eq(SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.count)
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
