# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_group_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagGroupLoader, type: :model, loader: true do
  subject(:record_loader) do
    described_class.new(directory: test_directory, files: selected_files)
  end

  before do
    create :adapter_type, name: 'Sanger 168'
  end

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tag_groups') }

  context 'with two_entry_example selected' do
    let(:selected_files) { 'two_entry_example' }
    let(:expected_attributes) do
      {
        name: 'Tag Group 1',
        adapter_type_name: 'Sanger 168',
        visible: true
      }
    end

    it 'creates two records' do
      expect { record_loader.create! }.to change(TagGroup, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(TagGroup, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(TagGroup.first).to have_attributes(expected_attributes)
    end
  end
end
