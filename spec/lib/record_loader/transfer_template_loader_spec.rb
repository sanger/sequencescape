# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/transfer_template_loader'

RSpec.describe RecordLoader::TransferTemplateLoader, type: :model, loader: true do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/transfer_templates') }

  context 'with bioscan_transfer_templates' do
    let(:selected_files) { 'one_transfer_template.yml' }

    it 'creates records' do
      expect { record_loader.create! }.to change(TransferTemplate, :count).by(1)
    end

    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(TransferTemplate, :count)
    end

    it 'sets attributes' do
      record_loader.create!

      record = TransferTemplate.first

      expect(record).to have_attributes(
        name: 'plate to tube',
        transfer_class_name: 'Transfer::FromPlateToTube',
        transfers: ['A1', 'A2', 'A3']
      )
    end
  end
end
