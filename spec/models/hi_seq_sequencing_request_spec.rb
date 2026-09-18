# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HiSeqSequencingRequest do
  let(:request) { create(:hi_seq_sequencing_request) }
  let(:validator) { described_class::NovaSeqXPERequestOptionsValidator.new(request) }

  before do
    request.request_metadata.assign_attributes(requested_flowcell_type: flowcell_type, read_length: read_length)
  end

  describe 'read length by flowcell type' do
    context 'with the 1.5B flowcell type' do
      let(:flowcell_type) { '1.5B' }

      [50, 100, 150, 300].each do |valid_read_length|
        context "when the read length is #{valid_read_length}" do
          let(:read_length) { valid_read_length }

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

    context 'with the 10B flowcell type' do
      let(:flowcell_type) { '10B' }

      [50, 100, 150].each do |valid_read_length|
        context "when the read length is #{valid_read_length}" do
          let(:read_length) { valid_read_length }

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

      context 'when the read length is 300' do
        let(:read_length) { 300 }

        it 'is not valid in the validator' do
          validator.validate
          expect(validator).not_to be_valid
        end

        it 'has the correct error message from the validator' do
          validator.validate
          expect(validator.errors[:read_length]).to include(
            '300 is only available for the 1.5B flowcell type. ' \
            'Available read lengths for the 10B flowcell type are 50, 100, 150.'
          )
        end
      end
    end

    context 'when no flowcell type is selected' do
      let(:flowcell_type) { nil }

      context 'when the read length is 300' do
        let(:read_length) { 300 }

        it 'is not valid in the validator' do
          validator.validate
          expect(validator).not_to be_valid
        end

        it 'has the correct error message from the validator' do
          validator.validate
          expect(validator.errors[:read_length]).to include(
            '300 is only available for the 1.5B flowcell type, but no flowcell type was selected.'
          )
        end
      end

      context 'when the read length is 150' do
        let(:read_length) { 150 }

        it 'has no errors in the validator' do
          validator.validate
          expect(validator.errors).to be_empty
        end
      end
    end
  end
end
