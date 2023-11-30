# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/pipeline_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::PipelineLoader, :loader, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/pipelines') }

  context 'with two_entry_example selected' do
    let!(:request_type) { create(:request_type, key: 'illumina_htp_novaseq_6000_paired_end_sequencing') }
    let(:selected_files) { 'two_entry_example' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(Pipeline, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(Pipeline, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(Pipeline.first.request_types.first.key).to eq(request_type.key)
      expect(Pipeline.first.workflow.name).to eq('NovaSeq 6001 PE')
    end
  end
end
