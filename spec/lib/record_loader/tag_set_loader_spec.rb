# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_set_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagSetLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tag_sets') }

  context 'with tag_sets_basic selected' do
    let(:selected_files) { 'tag_sets_basic' }
    # Required tag groups referenced by the tag sets
    let!(:tag_group1) { create(:tag_group, name: 'Tag Group 1') }
    let!(:tag_group2) { create(:tag_group, name: 'Tag Group 2') }
    let!(:tag_group3) { create(:tag_group, name: 'Tag Group 3') }

    it 'creates two records' do
      expect { record_loader.create! }.to change(TagSet, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader }.not_to change(TagSet, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      ts1 = TagSet.find_by(name: 'Tag Set 1')
      ts2 = TagSet.find_by(name: 'Tag Set 2')

      expect(ts1).to have_attributes(name: 'Tag Set 1', tag_group_id: tag_group1.id, tag2_group_id: nil)

      expect(ts2).to have_attributes(name: 'Tag Set 2', tag_group_id: tag_group2.id, tag2_group_id: tag_group3.id)
    end
  end
end
