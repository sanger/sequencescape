# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_group_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagGroupLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  before { create(:adapter_type, name: 'Sanger 168') }

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

  describe '#create_or_update!' do
    let(:adapter_type) { create(:adapter_type) }
    let(:other_adapter_type) { create(:adapter_type) }
    let(:section_name) { 'TestGroup' }
    let(:tags) { { 1 => 'ATCG', 2 => 'GCTA' } }
    let(:loader) { described_class.new }

    it 'sets the TagGroup name to section_name if not provided in options' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect(tag_group.name).to eq(section_name)
    end

    it 'uses the name from options if provided' do
      options = { 'name' => 'CustomName', 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect(tag_group.name).to eq('CustomName')
    end

    it 'assigns the correct adapter_type' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect(tag_group.adapter_type).to eq(adapter_type)
    end

    it 'creates the correct number of tags' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect(tag_group.tags.count).to eq(2)
    end

    it 'creates tags with the correct oligos' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect(tag_group.tags.pluck(:oligo)).to match_array(%w[ATCG GCTA])
    end

    it 'does not duplicate tags if already present' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect do
        loader.create_or_update!(section_name, options)
      end.not_to(change { tag_group.tags.count })
    end

    # rubocop:disable RSpec/ExampleLength
    it 'updates adapter_type_id if different' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      # Now update to a different adapter_type
      options = { 'adapter_type_name' => other_adapter_type.name }
      loader.create_or_update!(section_name, options)
      tag_group.reload
      expect(tag_group.adapter_type).to eq(other_adapter_type)
    end
    # rubocop:enable RSpec/ExampleLength

    it 'does nothing if adapter_type_id is the same' do
      options = { 'tags' => tags, 'adapter_type_name' => adapter_type.name }
      tag_group = loader.create_or_update!(section_name, options)
      expect do
        loader.create_or_update!(section_name, options)
      end.not_to(change { tag_group.reload.adapter_type_id })
    end
  end
end
