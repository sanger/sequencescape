# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UltimaSequencingRequest, type: :model do
  let(:request) { create(:ultima_sequencing_request) }

  describe 'Validations' do
    context 'when all attributes are valid' do
      it 'is valid' do
        expect(request).to be_valid
      end
    end

    context 'when fragment_size_required_from is less than 1' do
      it 'is invalid and displays fragment size from error message' do
        request.request_metadata.fragment_size_required_from = 0
        request.validate
        expect(request.errors[:'request_metadata.fragment_size_required_from']).to include(
          'must be greater than or equal to 1'
        )
      end
    end

    context 'when fragment_size_required_to is less than 1' do
      it 'is invalid and displays fragment size to error message' do
        request.request_metadata.fragment_size_required_to = 0
        request.validate
        expect(request.errors[:'request_metadata.fragment_size_required_to']).to include(
          'must be greater than or equal to 1'
        )
      end
    end

    context 'when ot_recipe value is not assigned' do
      it 'is invalid and displays required percent phix requested error message' do
        request.request_metadata.ot_recipe = nil
        request.validate
        expect(request.errors[:'request_metadata.ot_recipe']).to include("can't be blank")
      end
    end
  end
end
