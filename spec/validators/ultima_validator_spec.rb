# frozen_string_literal: true
require 'rails_helper'

describe UltimaValidator do
  describe '#validate' do
    subject(:validator) { described_class.new }

    context 'when batch contains two requests' do
      let(:record) { create(:batch, request_count: 2) }

      it 'is valid' do
        validator.validate(record)
        expect(record.errors[:base]).to be_empty
      end
    end

    context 'when batch contains a single request' do
      let(:record) { create(:batch, request_count: 1) }

      it 'is invalid' do
        validator.validate(record)
        expect(record.errors[:base]).to include(described_class::ERROR_MSG)
      end
    end
  end
end
