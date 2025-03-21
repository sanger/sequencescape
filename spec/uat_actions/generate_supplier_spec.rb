# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSupplier do
  context 'with valid options' do
    let(:uat_action) { described_class.new(parameters) }
    let(:supplier_name) { 'Test Supplier' }
    let(:parameters) { { supplier_name: } }

    describe '#perform' do
      context 'when generating a supplier' do
        it 'generates a supplier' do
          expect { uat_action.perform }.to(change(Supplier, :count).by(1))
        end

        it 'creates the supplier with the correct data' do
          uat_action.perform
          expect(Supplier.last.name).to eq supplier_name
        end
      end

      context 'when supplier already exists' do
        before { create(:supplier, name: supplier_name) }

        it 'does not create a new supplier' do
          expect { uat_action.perform }.not_to(change(Supplier, :count))
        end

        it 'does not change the supplier name' do
          uat_action.perform
          expect(uat_action.report['supplier_id']).to eq Supplier.find_by(name: supplier_name).id
        end
      end
    end
  end

  describe '#default' do
    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end
  end
end
