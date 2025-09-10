# frozen_string_literal: true
require 'rails_helper'

describe UltimaValidator do
  describe '#validate' do
    subject(:validator) { described_class.new }

    let(:record) { create(:batch, request_count: 2) }

    context 'when batch contains two requests' do
      it 'is valid' do
        validator.validate(record)
        expect(validator.validate(record)).to be_nil
      end
    end

    context 'when batch contains a single request' do
      let(:request) { create(:request, request_metadata: create(:request_metadata, read_length: 75)) }

      before { record.requests = [request] }

      it 'is invalid' do
        validator.validate(record)
        expect(record.errors[:base]).to include('Batches must contain exactly two requests.')
      end
    end
  end
end
