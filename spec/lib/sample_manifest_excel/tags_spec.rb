require 'rails_helper'

RSpec.describe SampleManifestExcel::Tags, type: :model, sample_manifest_excel: true do

  describe 'example_data' do

    let(:data) { SampleManifestExcel::Tags::ExampleData.new }

    it 'can produce a list of tags of an appropriate length' do
      tags = data.take(0, 4)
      expect(tags.length).to eq(5)
      expect(tags[0]).to have_key(:tag_oligo)
      expect(tags[0]).to have_key(:tag2_oligo)
      expect(tags[tags.keys.first]).to_not eq(tags[tags.keys.last])
    end

    it 'can produce a list of tags with a duplicate' do
      tags = data.take(0, 4, true)
      expect(tags[tags.keys.first]).to eq(tags[tags.keys.last])
    end
  end

  describe 'validator' do

    class TestTagChecker

      include ActiveModel::Model
      include SampleManifestExcel::Tags::Validator

      attr_reader :upload

      def initialize(upload)
        @upload = upload
      end
    end


    before(:all) do
      SampleManifestExcel.configure do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    let(:test_file) { 'test.xlsx' }
    let(:columns)   { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }

    it 'fails if the tags are invalid' do
      download = build(:test_download, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, manifest_type: 'multiplexed_library', validation_errors: [:tags])
      download.save(test_file)
      upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup , start_row: 9)
      expect(TestTagChecker.new(upload)).to_not be_valid
    end

    after(:each) do
      File.delete(test_file) if File.exist?(test_file)
    end

    after(:all) do
      SampleManifestExcel.reset!
    end
  end
end