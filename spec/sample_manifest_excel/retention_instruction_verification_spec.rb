# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Download, :sample_manifest, :sample_manifest_excel, type: :model do
  let(:test_file) { 'retention_test.xlsx' }

  before do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  after do
    SampleManifestExcel.reset!
    File.delete(test_file) if File.exist?(test_file)
  end

  shared_examples 'manifest with retention instruction' do |template_name, config_column|
    let(:sample_manifest) { create(:tube_sample_manifest) }
    let(:download) do
      described_class.new(
        sample_manifest,
        SampleManifestExcel.configuration.columns.public_send(config_column).dup,
        SampleManifestExcel.configuration.ranges.dup
      )
    end

    let(:spreadsheet) do
      download.save(test_file)
      Roo::Spreadsheet.open(test_file)
    end

    let(:headers) do
      header_row = spreadsheet.sheet(0).each_row_streaming(pad_cells: true).find do |row|
        row.map { |cell| cell&.value }.include?('SANGER SAMPLE ID')
      end

      header_row.map { |cell| cell&.value }
    end

    it "includes the Retention Instruction column for #{template_name}" do
      expect(headers).to include('RETENTION INSTRUCTION')
    end
  end

  context 'with Default Tube template' do
    it_behaves_like 'manifest with retention instruction', 'Default Tube', :tube_default
  end

  context 'with Long Read template' do
    it_behaves_like 'manifest with retention instruction', 'Long Read', :long_read
  end
end
