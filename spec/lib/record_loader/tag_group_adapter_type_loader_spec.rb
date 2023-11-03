# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_group_adapter_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagGroupAdapterTypeLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tag_group_adapter_types') }

  context 'with tag_group_adapter_types_basic selected' do
    let(:selected_files) { 'tag_group_adapter_types_basic' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(TagGroup::AdapterType, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(TagGroup::AdapterType, :count)
    end
  end
end
