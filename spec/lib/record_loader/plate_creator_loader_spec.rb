# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/plate_creator_loader'

RSpec.describe RecordLoader::PlateCreatorLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/plate_creators') }

  context 'when create is invoked' do
    let(:selected_files) { '000_example' }

    before do
      create(:plate_purpose, name: 'Stock RNA Plate')
      a_new_record_loader.create!
    end

    it 'creates a new plate creator' do
      expect(Plate::Creator.where(name: 'Stock RNA Plate').count).to eq(1)
    end
  end
end
