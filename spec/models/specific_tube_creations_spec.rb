# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpecificTubeCreation do
  shared_context 'with common setup' do
    subject(:specific_tube_creation) { described_class.new(creation_parameters) }

    let(:child_purpose) { create(:tube_purpose) }
    let(:user) { create(:user) }
    let(:parent) { create(:plate) }
  end

  shared_context 'with common test setup' do
    before do
      expect(specific_tube_creation.save).to (be true),
      -> { "Failed to save: #{specific_tube_creation.errors.full_messages}" }
    end

    let(:first_child) { specific_tube_creation.children.first }
  end

  shared_examples 'with common tests' do
    it 'creates one child' do
      expect(specific_tube_creation.children.count).to eq purpose_count
    end

    it 'creates a tube' do
      expect(first_child).to be_a Tube
    end

    it 'sets the purpose' do
      expect(first_child.purpose).to eq child_purpose
    end

    it 'sets expected names' do
      specific_tube_creation.children.each_with_index { |child, i| expect(child.name).to eq names[i] }
    end

    it 'sets plates as parents' do
      specific_tube_creation.children.each { |child| expect(child.parents).to include(parent) }
    end
  end

  shared_examples 'a specific tube creator' do
    include_context 'with common setup'

    describe '#save' do
      include_context 'with common test setup'
      it_behaves_like 'with common tests'
    end
  end

  context 'with no custom names' do
    let(:names) { [nil] * purpose_count }
    let(:creation_parameters) { { user: user, child_purposes: [child_purpose] * purpose_count, parent: parent } }

    context 'with one child purpose' do
      let(:purpose_count) { 1 }

      it_behaves_like 'a specific tube creator'
    end

    context 'with two child purpose' do
      let(:purpose_count) { 2 }

      it_behaves_like 'a specific tube creator'
    end
  end

  context 'with custom names' do
    let(:names) { %w[example_1 example_2] }
    let(:purpose_count) { 2 }
    let(:tube_attributes) { names.map { |name| { name: } } }
    let(:creation_parameters) do
      { user: user, child_purposes: [child_purpose] * purpose_count, parent: parent, tube_attributes: tube_attributes }
    end

    it_behaves_like 'a specific tube creator'
  end

  context 'with foreign barcodes' do
    include_context 'with common setup'

    let(:names) { ['example_1'] }
    let(:purpose_count) { 1 }
    let(:foreign_barcode) { 'FD00000001' }
    let(:tube_attributes) { [{ name: names[0], foreign_barcode: foreign_barcode }] }
    let(:creation_parameters) do
      { user: user, child_purposes: [child_purpose], parent: parent, tube_attributes: tube_attributes }
    end

    describe '#save' do
      include_context 'with common test setup'
      let(:expected_barcode_format) { 'fluidx_barcode' }

      it_behaves_like 'with common tests'

      it 'sets the foreign barcode as the primary barcode' do
        expect(first_child.primary_barcode.barcode).to eq foreign_barcode
      end

      it 'sets the expected foreign barcode format' do
        expect(first_child.primary_barcode.format).to eq expected_barcode_format
      end
    end

    context 'with unrecognised barcode format' do
      let(:foreign_barcode) { 'X' } # no matching format
      let(:expected_error_msg) { "Cannot determine format for foreign barcode #{foreign_barcode}" }

      it 'rejects the save if the barcode format is not recognised' do
        expect { specific_tube_creation.save }.to raise_error(RuntimeError, expected_error_msg)
      end
    end

    context 'with a foreign barcode that has already been used' do
      let(:existing_barcode) { create(:barcode, format: 'fluidx_barcode', barcode: foreign_barcode) }
      let(:existing_tube) { create(:sample_tube, barcodes: [existing_barcode]) }
      let(:expected_error_msg) { "Foreign Barcode: #{foreign_barcode} is already in use!" }

      before { existing_tube }

      it 'rejects the save if the barcode format is not recognised' do
        expect { specific_tube_creation.save }.to raise_error(RuntimeError, expected_error_msg)
      end
    end
  end
end
