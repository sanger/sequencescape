# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_group_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagGroupLoader, type: :model, loader: true do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  before { create :adapter_type, name: 'Sanger 168' }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tag_groups') }

  context 'with tag_groups_basic selected' do
    let(:selected_files) { 'tag_groups_basic' }
    let(:expected_attributes) { { name: 'Tag Group 1', adapter_type_name: 'Sanger 168', visible: true } }

    it 'creates two records' do
      expect { record_loader.create! }.to change(TagGroup, :count).by(2)
    end

    it 'creates two tags' do
      expect { record_loader.create! }.to change(Tag, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to(change(TagGroup, :count) && change(Tag, :count))
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(TagGroup.first).to have_attributes(expected_attributes)
    end
  end
end
