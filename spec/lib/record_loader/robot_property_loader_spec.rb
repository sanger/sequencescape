# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/robot_property_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::RobotPropertyLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/robot_properties') }

  context 'with robot_properties_example yml file selected' do
    let(:selected_files) { 'robot_properties_example' }

    before do
      create(:robot, name: 'Robot 1')
      create(:robot, name: 'Robot 2')
    end

    it 'creates seven records' do
      expect { record_loader.create! }.to change(RobotProperty, :count).by(7)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(RobotProperty, :count)
    end

    context 'when setting robot property attributes' do
      let(:expected_attributes) { { name: 'Destination', value: '1', key: 'DEST1' } }

      it 'attributes match expected' do
        record_loader.create!
        expect(RobotProperty.last).to have_attributes(expected_attributes)
      end
    end
  end
end
