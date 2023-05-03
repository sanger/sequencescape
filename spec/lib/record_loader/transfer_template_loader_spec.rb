# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/transfer_template_loader'

RSpec.describe RecordLoader::TransferTemplateLoader, type: :model, loader: true do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/transfer_templates') }

  context 'with bioscan_transfer_templates' do
    let(:selected_files) { 'example_transfer_templates.yml' }

    it 'creates records' do
      expect { record_loader.create! }.to change(TransferTemplate, :count).by(3)
    end

    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(TransferTemplate, :count)
    end

    it 'sets attributes for plate to tube transfer' do
      record_loader.create!

      record = TransferTemplate.find_by(name: 'plate to tube')

      expect(record).to have_attributes(
        name: 'plate to tube',
        transfer_class_name: 'Transfer::FromPlateToTube',
        transfers: %w[A1 A2 A3] # array of locations
      )
    end

    it 'sets attributes for plate to plate transfer' do
      record_loader.create!

      record = TransferTemplate.find_by(name: 'plate to plate')

      expect(record).to have_attributes(
        name: 'plate to plate',
        transfer_class_name: 'Transfer::BetweenPlates',
        transfers: {"A1" => "H12", "A2" => "H11", "A3" => "H10"}  # mapping of locations
      )
    end

    it 'sets attributes if no locations given' do
      record_loader.create!

      record = TransferTemplate.find_by(name: 'no locations')

      expect(record).to have_attributes(
        name: 'no locations',
        transfer_class_name: 'Transfer::BetweenPlates',
        transfers: nil  # not given
      )
    end
  end
end
