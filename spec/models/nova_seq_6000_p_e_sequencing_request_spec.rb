# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NovaSeq6000PESequencingRequest, type: :model do
  let(:request) { create(:nova_seq_6000_p_e_sequencing_request) }
  let(:validator) { NovaSeq6000PESequencingRequest::NovaSeq6000PERequestOptionsValidator.new(request) }

  # request.validate is testing the validation in the custom attribute method
  # and the validator.validate is testing the validation in the 'NovaSeq6000PERequestOptionsValidator' class
  describe 'Validations' do
    context 'when flowcell type is SP and read length is 250' do
      let(:metadata) do
        { requested_flowcell_type: 'SP', read_length: 250, fragment_size_required_from: 150,
          fragment_size_required_to: 400 }
      end

      before do
        request.request_metadata.assign_attributes(metadata)
      end

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is SP and read length is not 250' do
      let(:metadata) do
        { requested_flowcell_type: 'SP', read_length: 150, fragment_size_required_from: 150,
          fragment_size_required_to: 400 }
      end

      before do
        request.request_metadata.assign_attributes(metadata)
      end

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end

    context 'when flowcell type is not SP and read length is 250' do
      let(:metadata) do
        { requested_flowcell_type: 'S4', read_length: 250, fragment_size_required_from: 150,
          fragment_size_required_to: 400 }
      end

      before do
        request.request_metadata.assign_attributes(metadata)
      end

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'is not valid in the validator' do
        validator.validate
        expect(validator).not_to be_valid
      end

      it 'has the correct error message from the validator' do
        validator.validate
        expect(validator.errors[:read_length]).to include(
          'The user can only select a Read Length of 250 with the SP flowcell type for NovaSeq 6000 PE requests'
        )
      end
    end

    context 'when flowcell type is not SP and read length is not 250' do
      let(:metadata) do
        { requested_flowcell_type: 'S4', read_length: 150, fragment_size_required_from: 150,
          fragment_size_required_to: 400 }
      end

      before do
        request.request_metadata.assign_attributes(metadata)
      end

      it 'is valid in the class' do
        request.validate
        expect(request).to be_valid
      end

      it 'has no errors in the validator' do
        validator.validate
        expect(validator.errors).to be_empty
      end
    end
  end
end
