# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/primer_panel_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::PrimerPanelLoader, loader: true, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/primer_panels') }

  context 'with primer_panels_basic selected' do
    let(:selected_files) { 'primer_panels_basic' }
    let(:expected_attributes) do
      {
        name: 'Unique attribute',
        snp_count: 2,
        programs: {
          'pcr 1' => {
            'name' => 'example',
            'duration' => '225'
          },
          'pcr 2' => {
            'name' => 'example_2',
            'duration' => '120'
          }
        }
      }
    end

    it 'creates two records' do
      expect { record_loader.create! }.to change(PrimerPanel, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(PrimerPanel, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(PrimerPanel.first).to have_attributes(expected_attributes)
    end
  end
end
