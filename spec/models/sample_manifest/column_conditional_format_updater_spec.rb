# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifest::ColumnConditionalFormatUpdater do
  let(:columns) { instance_double(SequencescapeExcel::Column) }

  describe '#library_asset?' do
    subject { described_class.new(columns:, asset_type:).library_asset? }

    context 'when asset type is a library' do
      let(:asset_type) { 'library_plate' }

      it { is_expected.to be true }
    end

    context 'when asset type is not a library' do
      let(:asset_type) { 'plate' }

      it { is_expected.to be false }
    end
  end

  describe '#update_column_formatting_by_asset_type' do
    before do
      SampleManifestExcel.configure do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    context 'when asset type is a library' do
      let(:columns) { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences }
      let(:asset_type) { 'library' }
      let(:updater) { described_class.new(columns:, asset_type:) }
      let(:required_column) { columns.find_by(:name, 'library_type') }
      let(:non_required_column) { columns.find_by(:name, 'reference_genome') }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'updates the conditional format for the required columns' do
        init_required_column_format = required_column.conditional_formattings.find_by(:name, 'empty_cell')
        expect(init_required_column_format).not_to be_nil
        updater.update_column_formatting_by_asset_type
        expect(required_column.conditional_formattings.find_by(:name, 'empty_cell')).to be_nil
        expect(required_column.conditional_formattings.find_by(:name, 'empty_mandatory_cell')).not_to be_nil
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations

      it 'does not change the format for non-required columns' do
        initial_format = non_required_column.conditional_formattings.dup
        updater.update_column_formatting_by_asset_type
        expect(non_required_column.conditional_formattings).to eq(initial_format)
      end
    end

    context 'when asset type is not a library' do
      let(:columns) { SampleManifestExcel.configuration.columns.tube_multiplexed_library }
      let(:asset_type) { 'multiplexed_library' }
      let(:updater) { described_class.new(columns:, asset_type:) }
      let(:library_type_column) { columns.find_by(:name, 'library_type') }

      it 'does not update the conditional format' do
        initial_format = library_type_column.conditional_formattings.dup

        updater.update_column_formatting_by_asset_type

        expect(library_type_column.conditional_formattings).to eq(initial_format)
      end
    end
  end
end
