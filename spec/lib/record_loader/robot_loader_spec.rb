# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/robot_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::RobotLoader, loader: true, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/robots') }

  context 'with robots_example yml file selected' do
    let(:selected_files) { 'robots_example' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(Robot, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(Robot, :count)
    end

    context 'when setting robot attributes' do
      let(:expected_attributes) { { name: 'Robot 2', location: 'Room 2', barcode: '5678' } }

      it 'attributes match expected' do
        record_loader.create!
        expect(Robot.last).to have_attributes(expected_attributes)
      end
    end
  end
end
