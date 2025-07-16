# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/plate_creator_loader'

RSpec.describe RecordLoader::PlateCreatorLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/plate_creators') }

  context 'when create is invoked for a creator that does not exist' do
    let(:selected_files) { '000_example' }

    before do
      create(:plate_purpose, name: 'Stock RNA Plate')
      create(:plate_purpose, name: 'Parent Stock Plate')
      a_new_record_loader.create!
    end

    it 'creates a new plate creator' do
      expect(Plate::Creator.where(name: 'Stock RNA Plate').count).to eq(1)
    end

    it 'populates purpose_relationship table' do
      expect(Plate::Creator.find_by(name: 'Stock RNA Plate')&.plate_creator_purposes&.count).to eq(1)
    end

    it 'populates parent_purpose_relationship table' do
      expect(Plate::Creator.find_by(name: 'Stock RNA Plate')&.parent_purpose_relationships&.count).to eq(1)
    end
  end

  context 'when create is invoked for a creator that does exist' do
    let(:selected_files) { '001_example' }

    before do
      create(:plate_creator, name: 'Stock Plate')
    end

    it 'does not create a new plate creator' do
      expect { a_new_record_loader.create! }.not_to(change(Plate::Creator, :count))
    end
  end

  context 'when the plate purpose does not exist' do
    let(:selected_files) { '000_example' }

    it 'raises an error' do
      expect { a_new_record_loader.create! }.to raise_error(StandardError)
    end
  end
end
