# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HiSeqSequencingRequest do
  let(:request) { create(:hi_seq_sequencing_request) }
  let(:validator) { HiSeqSequencingRequest::NovaSeqXPERequestOptionsValidator.new(request) }

  # request.validate exercises the attribute-level validation (against the
  # request_type_validators valid_options list), while validator.validate
  # exercises only the cross-field validation added in this class.
  describe 'Validations' do
    context 'when flowcell type is 1.5B and read length is 300' do
      let(:metadata) { { requested_flowcell_type: '1.5B', read_length: 300 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is 1.5B and read length is 150 (still allowed additively)' do
      let(:metadata) { { requested_flowcell_type: '1.5B', read_length: 150 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is 1.5B and read length is not one of the allowed values' do
      let(:metadata) { { requested_flowcell_type: '1.5B', read_length: 75 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is not valid in the validator' do
        validator.validate
        expect(validator).not_to be_valid
      end

      it 'has the correct error message from the validator' do
        validator.validate
        expect(validator.errors[:read_length]).to include(
          'can only be one of 50, 100, 150, 300 when the flowcell type is 1.5B'
        )
      end
    end

    context 'when flowcell type is 10B and read length is 150' do
      let(:metadata) { { requested_flowcell_type: '10B', read_length: 150 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is 5B and read length is 100' do
      let(:metadata) { { requested_flowcell_type: '5B', read_length: 100 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is not 1.5B and read length is 300' do
      let(:metadata) { { requested_flowcell_type: '10B', read_length: 300 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is not valid in the validator' do
        validator.validate
        expect(validator).not_to be_valid
      end

      it 'has the correct error message from the validator' do
        validator.validate
        expect(validator.errors[:read_length]).to include(
          'can only be one of 50, 100, 150 when the flowcell type is not 1.5B'
        )
      end
    end

    context 'when flowcell type is 25B and read length is 300' do
      let(:metadata) { { requested_flowcell_type: '25B', read_length: 300 } }

      before { request.request_metadata.assign_attributes(metadata) }

      it 'is not valid in the validator' do
        validator.validate
        expect(validator).not_to be_valid
      end
    end
  end
end
