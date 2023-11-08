# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Tags, :sample_manifest, :sample_manifest_excel, type: :model do
  describe 'example_data' do
    let(:data) { SampleManifestExcel::Tags::ExampleData.new }

    it 'can produce a list of sequence tags of an appropriate length' do
      tags = data.take(0, 4)
      expect(tags.length).to eq(5)
      expect(tags[0]).to have_key(:i7)
      expect(tags[0]).to have_key(:i5)
      expect(tags[tags.keys.first]).not_to eq(tags[tags.keys.last])
    end

    it 'can produce a list of sequence tags with a duplicate' do
      tags = data.take(0, 4, true)
      expect(tags[tags.keys.first]).to eq(tags[tags.keys.last])
    end

    it 'can produce a list of tag groups and indexes' do
      tags = data.take_as_groups_and_indexes(0, 4)
      expect(tags.length).to eq(5)
      expect(tags[0]).to have_key(:tag_group)
      expect(tags[0]).to have_key(:tag_index)
      expect(tags[0]).to have_key(:tag2_group)
      expect(tags[0]).to have_key(:tag2_index)
      expect(tags[tags.keys.first]).not_to eq(tags[tags.keys.last])
    end

    it 'can produce a list of tag groups and indexes with a duplicate' do
      tags = data.take_as_groups_and_indexes(0, 4, true)
      expect(tags[tags.keys.first]).to eq(tags[tags.keys.last])
    end
  end

  describe 'validator' do
    class TestTagChecker
      include ActiveModel::Model
      include SampleManifestExcel::Tags::Validator::Uniqueness

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

    let(:test_file_name) { 'test.xlsx' }
    let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }

    after(:all) { SampleManifestExcel.reset! }

    after { File.delete(test_file_name) if File.exist?(test_file_name) }

    context 'tag sequences' do
      let(:columns) { SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup }

      it 'fails if the tags are invalid' do
        download =
          build(
            :test_download_tubes,
            columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
            manifest_type: 'tube_multiplexed_library_with_tag_sequences',
            validation_errors: [:tags]
          )
        download.save(test_file_name)
        upload =
          SampleManifestExcel::Upload::Base.new(
            file: test_file,
            column_list: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
            start_row: 9
          )
        expect(TestTagChecker.new(upload)).not_to be_valid
      end
    end

    context 'tag groups and indexes' do
      let(:columns) { SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup }

      it 'fails if the tags are invalid' do
        download =
          build(
            :test_download_tubes,
            columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup,
            manifest_type: 'tube_multiplexed_library',
            validation_errors: [:tags]
          )
        download.save(test_file_name)
        upload =
          SampleManifestExcel::Upload::Base.new(
            file: test_file,
            column_list: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup,
            start_row: 9
          )
        expect(TestTagChecker.new(upload)).not_to be_valid
      end
    end
  end

  describe 'clash_finder' do
    class TestTagClashesFinder
      include SampleManifestExcel::Tags::ClashesFinder
    end

    it 'finds tags clashes and creates tags clashes message' do
      tag_clashes_finder = TestTagClashesFinder.new
      tags_oligos_combinations = [%w[AA TT], %w[AA GC], %w[TT AA], %w[AA TT]]
      result = tag_clashes_finder.find_tags_clash(tags_oligos_combinations)
      expect(result).to eq(%w[AA TT] => [0, 3])
      message = tag_clashes_finder.create_tags_clashes_message(result)
      expect(message).to eq('Same tags AA, TT are used on rows 1, 4.')
      first_row = 5
      message_for_manifest = tag_clashes_finder.create_tags_clashes_message(result, first_row)
      expect(message_for_manifest).to eq('Same tags AA, TT are used on rows 6, 9.')
    end

    it 'finds nothing if there are no tag clashes' do
      tag_clashes_finder = TestTagClashesFinder.new
      tags_oligos_combinations = [%w[AA TT], %w[AA GC], %w[TT AA]]
      result = tag_clashes_finder.find_tags_clash(tags_oligos_combinations)
      expect(result).to eq({})
    end

    it 'finds nothing if receives an empty array' do
      tag_clashes_finder = TestTagClashesFinder.new
      result = tag_clashes_finder.find_tags_clash([])
      expect(result).to eq({})
    end
  end
end
