# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HiSeqSequencingRequest do
  let(:request) { create(:hi_seq_sequencing_request) }
  let(:validator) { described_class::NovaSeqXPERequestOptionsValidator.new(request) }

  before do
    request.request_metadata.assign_attributes(requested_flowcell_type: flowcell_type, read_length: read_length)
  end

  # request.validate tests the metadata validations, e.g. read length is in
  # the request type's list; validator.validate tests the 1.5B-only 300 rule.
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

  describe 'inherited fragment size validation' do
    let(:flowcell_type) { '1.5B' }
    let(:read_length) { 150 }

    before { request.request_metadata.fragment_size_required_from = 0 }

    it 'rejects a non-positive fragment size in the validator' do
      validator.validate
      expect(validator.errors[:fragment_size_required_from]).to be_present
    end
  end

  # Submissions validate request options on the order, which runs both the
  # request type's read length list and NovaSeqXPERequestOptionsValidator.
  describe 'order request options validation' do
    let(:request_type) do
      create(:nova_seq_x_sequencing_request_type,
             read_lengths: [50, 100, 150, 300])
    end
    let(:order) do
      build(:order,
            request_types: [request_type.id],
            request_options: { read_length: read_length,
                               requested_flowcell_type: flowcell_type })
    end
    let(:read_length_errors) { order.errors[:'request_options.read_length'] }

    before { order.validate }

    [
      { flowcell_type: '1.5B', read_length: '300' },
      { flowcell_type: '5B', read_length: '150' },
      { flowcell_type: '10B', read_length: '150' }
    ].each do |options|
      context "with #{options[:read_length]} and #{options[:flowcell_type]}" do
        let(:flowcell_type) { options[:flowcell_type] }
        let(:read_length) { options[:read_length] }

        it 'has no read length errors' do
          expect(read_length_errors).to be_empty
        end
      end
    end

    %w[5B 10B].each do |type|
      context "with 300 and #{type}" do
        let(:flowcell_type) { type }
        let(:read_length) { '300' }

        it 'rejects the read length' do
          expect(read_length_errors).to include(
            a_string_starting_with('300 is only available for the 1.5B')
          )
        end
      end
    end

    context 'with a read length not in the request type list' do
      let(:flowcell_type) { '1.5B' }
      let(:read_length) { '75' }

      it 'rejects the read length' do
        expect(read_length_errors).to include(a_string_including("is '75'"))
      end
    end
  end
end
