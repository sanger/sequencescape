# frozen_string_literal: true
require 'rails_helper'

describe ElementAvitiValidator do
  describe '#validate' do
    subject(:validator) { described_class.new }

    let(:record) { create(:batch, request_count: 2) }

    context 'when batch contains two requests' do
      before { record.requests.each { |request| request.request_metadata.read_length = read_length } }

      context 'with a read length different than 300' do
        let(:read_length) { 150 }

        it 'is valid' do
          expect(validator.validate(record)).to be true
        end
      end

      context 'with one request with a read length equals 300' do
        let(:read_length) { 300 }

        it 'is invalid' do
          expect(validator.validate(record)).to be false
        end
      end
    end

    context 'when batch contains a single request with read length 300' do
      let(:request) { create(:request, request_metadata: create(:request_metadata, read_length: 300)) }

      before { record.requests = [request] }

      it 'is valid' do
        expect(validator.validate(record)).to be true
      end
    end
  end
end
