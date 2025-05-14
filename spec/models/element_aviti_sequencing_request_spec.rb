# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ElementAvitiSequencingRequest, type: :model do
  let(:request) { create(:element_aviti_sequencing_request) }
  let(:validator) { ElementAvitiSequencingRequest::ElementAvitiRequestOptionsValidator.new(request) }

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

    context 'when percent_phix_requested value is not assigned' do
      it 'is invalid and displays required percent phix requested error message' do
        request.request_metadata.percent_phix_requested = nil
        request.validate
        expect(request.errors[:'request_metadata.percent_phix_requested']).to include("can't be blank")
      end
    end

    # Request.validate is testing the validation in the custom attribute method
    # and the validator.validate is testing the validation in the 'ElementAvitiRequestOptionsValidator' class

    context 'when percent_phix_requested is more than 100' do
      it 'is invalid and displays percent phix requested error' do
        request.request_metadata.percent_phix_requested = 101
        validator.validate
        expect(validator.errors[:percent_phix_requested]).to include('must be less than or equal to 100')
      end
    end

    context 'when percent_phix_requested is higher' do
      it 'is invalid and displays percent phix requested error' do
        request.request_metadata.percent_phix_requested = 101
        request.validate
        expect(request.errors[:'request_metadata.percent_phix_requested']).to include(
          'must be less than or equal to 100'
        )
      end
    end

    context 'when percent_phix_requested is lower' do
      it 'is invalid and displays percent phix requested error' do
        request.request_metadata.percent_phix_requested = -1
        request.validate
        expect(request.errors[:'request_metadata.percent_phix_requested']).to include(
          'must be greater than or equal to 0'
        )
      end
    end

    context 'when low_diversity value is not assigned' do
      it 'is invalid and displays required low diversity error message' do
        request.request_metadata.low_diversity = nil
        request.validate
        expect(request.errors[:'request_metadata.low_diversity']).to include("can't be blank")
      end
    end

    context 'when requested_flowcell_type is LO and read_length is not 150' do
      # rubocop:disable RSpec/ExampleLength
      it 'is invalid and displays error message' do
        request.request_metadata.requested_flowcell_type = 'LO'
        request.request_metadata.read_length = 300
        validator.validate
        expect(validator.errors[:read_length]).to include(
          'For the LO (Low Output) flowcell kit the user can select a Read Length of 150'
        )
      end
      # rubocop:enable RSpec/ExampleLength
    end
  end
end
