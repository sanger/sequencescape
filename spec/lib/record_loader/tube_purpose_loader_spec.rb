# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tube_purpose_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TubePurposeLoader, type: :model, loader: true do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tube_purposes') }

  context 'with two_entry_example selected' do
    let(:selected_files) { 'basic_tube_purposes' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(Tube::Purpose, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(Tube::Purpose, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(Tube::Purpose.first).to have_attributes(name: 'Tube Purpose Name', target_type: 'LibraryTube')
    end
  end
end
