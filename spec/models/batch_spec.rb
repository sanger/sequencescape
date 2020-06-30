# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch, type: :model do
  describe '::barcode_without_pick_number' do
    subject { described_class.barcode_without_pick_number(barcode_to_split) }

    let(:batch_bacode) { '550000555760' }

    context 'with a legacy barcode' do
      let(:barcode_to_split) { batch_bacode }

      it { is_expected.to eq batch_bacode }
    end

    context 'with an extended barcode' do
      let(:barcode_to_split) { "#{batch_bacode}-3" }

      it { is_expected.to eq batch_bacode }
    end
  end

  describe '::extract_pick_number' do
    subject(:extract_pick_number) { described_class.extract_pick_number(barcode_to_split) }

    let(:batch_bacode) { '550000555760' }

    # Legacy batches should return the first set
    context 'with a legacy barcode' do
      let(:barcode_to_split) { batch_bacode }

      it { is_expected.to eq 1 }
    end

    context 'with an extended barcode' do
      let(:barcode_to_split) { "#{batch_bacode}-3" }

      it { is_expected.to eq 3 }
    end

    context 'with an invalid input' do
      let(:barcode_to_split) { "#{batch_bacode}-notanumber" }

      it 'raises an error' do
        expect { extract_pick_number }.to raise_error(ArgumentError)
      end
    end
  end
end
