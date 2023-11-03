# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::TestDownload, :sample_manifest, :sample_manifest_excel, type: :model do
  attr_reader :spreadsheet

  let(:test_file) { 'test.xlsx' }
  let(:download) do
    described_class.new(
      columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
      data: {},
      no_of_rows: 5,
      study: 'WTCCC',
      supplier: 'Test supplier',
      count: 1,
      type: 'Tubes'
    )
  end

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  after(:all) { SampleManifestExcel.reset! }

  after { File.delete(test_file) if File.exist?(test_file) }

  it 'creates a file' do
    expect(File.file?(test_file))
  end

  it 'creates a worksheet with some data' do
    expect(download.worksheet.columns.count).to eq(
      SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.count
    )
  end
end
