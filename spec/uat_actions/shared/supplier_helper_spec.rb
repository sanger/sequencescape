# frozen_string_literal: true
require 'rails_helper'

class SupplierHelperTestUatAction < UatActions
  include UatActions::Shared::SupplierHelper

  form_field :supplier_name,
             :select,
             label: 'Supplier Name',
             help: 'The supplier under which samples originated.',
             select_options: -> { Supplier.alphabetical.pluck(:name) }
end

RSpec.describe UatActions::Shared::SupplierHelper do
  subject(:uat_action) { SupplierHelperTestUatAction.new(parameters) }

  context 'when supplier_name is specified' do
    let(:supplier_name) { 'test-supplier-name' }
    let(:parameters) { { supplier_name: } }

    context 'when the supplier exists' do
      before { create(:supplier, name: supplier_name) }

      it 'returns the supplier' do
        expect(uat_action.send(:supplier)).to eq(Supplier.find_by(name: supplier_name))
      end
    end

    context 'when the supplier does not exist' do
      it 'adds an error' do # rubocop:disable RSpec/MultipleExpectations
        expect(uat_action).not_to be_valid
        expect(uat_action.errors[:supplier_name]).to include(
          format(described_class::ERROR_SUPPLIER_DOES_NOT_EXIST, supplier_name)
        )
      end
    end
  end

  context 'when supplier_name is not specified' do
    let(:parameters) { {} } # i.e. { supplier_name: nil }

    it 'returns the default supplier' do
      expect(uat_action.send(:supplier)).to eq(UatActions::StaticRecords.supplier)
    end
  end
end
