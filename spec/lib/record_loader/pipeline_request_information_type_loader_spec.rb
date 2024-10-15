# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/pipeline_request_information_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::PipelineRequestInformationTypeLoader, :loader, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/pipeline_request_information_types') }

  before do
    create(:pipeline, name: 'Pipeline 1')
    create(:request_information_type, key: 'key')
    create(:request_information_type, key: 'key2')
  end

  context 'with two_entry_example selected' do
    let(:selected_files) { 'two_entry_example' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(PipelineRequestInformationType, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(PipelineRequestInformationType, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(PipelineRequestInformationType.first.pipeline.name).to eq('Pipeline 1')
      expect(PipelineRequestInformationType.first.request_information_type.key).to eq('key')
    end
  end
end
