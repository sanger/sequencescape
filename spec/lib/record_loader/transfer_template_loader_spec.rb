# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/transfer_template_loader'

RSpec.describe RecordLoader::TransferTemplateLoader, type: :model, loader: true do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/transfer_templates') }

  context 'with bioscan_transfer_templates' do
    let(:selected_files) { 'bioscan_transfer_templates' }

    it 'creates 18 records' do
      expect { record_loader.create! }.to change(TransferTemplate, :count).by(18)
    end

    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(TransferTemplate, :count)
    end

    it 'sets attributes on plate-to-plate transfers' do
      record_loader.create!
      record = TransferTemplate.find_by(name: 'Transfer columns 1-1')

      expect(record).to have_attributes(
        name: 'Transfer columns 1-1',
        transfer_class_name: 'Transfer::BetweenPlates',
        transfers: "---\nA1: A1\nB1: B1\nC1: C1\nD1: D1\nE1: E1\nF1: F1\nG1: G1\nH1: H1\n"
      )
    end

    it 'sets attributes on plate-to-tube transfers' do
      record_loader.create!
      record = TransferTemplate.find_by(name: '384 plate to tube')

      def locations_for(row_range, column_range)
        row_range.map { |row| column_range.map { |column| "#{row}#{column}" } }.flatten
      end
      
      wells_384_locations = locations_for(('A'..'P'), (1..24))

      expect(record).to have_attributes(
        name: '384 plate to tube',
        transfer_class_name: 'Transfer::FromPlateToTube',
        transfers: wells_384_locations.to_yaml
      )
    end

    it 'sets transfers attribute to nil if not given' do
      record_loader.create!
      record = TransferTemplate.find_by(name: 'Pool wells based on submission')

      expect(record).to have_attributes(
        name: 'Pool wells based on submission',
        transfer_class_name: 'Transfer::BetweenPlatesBySubmission',
        transfers: nil
      )
    end
  end
end
