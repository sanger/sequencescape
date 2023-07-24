# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/flowcell_type_request_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::FlowcellTypeRequestTypeLoader, type: :model, loader: true do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/flowcell_types_request_types') }

  context 'with two_entry_example selected' do
    let(:selected_files) { 'two_entry_example' }
    let!(:flowcell) { create(:flowcell_type, name: 'SP') }
    let!(:request_type) { create(:request_type, key: 'illumina_htp_novaseq_6000_paired_end_sequencing') }

    before { create(:flowcell_type, name: 'SP2') }

    it 'creates two records' do
      expect { record_loader.create! }.to change(FlowcellTypesRequestType, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(FlowcellTypesRequestType, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(FlowcellTypesRequestType.first.flowcell_type_id).to eq(flowcell.id)
      expect(FlowcellTypesRequestType.first.request_type_id).to eq(request_type.id)
    end
  end
end
