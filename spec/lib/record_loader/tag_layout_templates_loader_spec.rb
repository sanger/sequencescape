# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tag_layout_templates_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TagLayoutTemplatesLoader, type: :model, loader: true do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tag_layout_templates') }

  context 'with tag_layout_template_basic selected' do
    let(:selected_files) { 'tag_layout_template_basic' }
    let(:expected_attributes) do
      {
        name: 'Tag Layout 1',
        tag_group: tag_group,
        tag2_group: tag2_group,
        direction: 'column',
        walking_by: 'wells of plate'
      }
    end

    let!(:tag_group) { create :tag_group, name: 'group 1' }
    let!(:tag2_group) { create :tag_group, name: 'group 2' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(TagLayoutTemplate, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(TagLayoutTemplate, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(TagLayoutTemplate.first).to have_attributes(expected_attributes)
    end
  end
end
