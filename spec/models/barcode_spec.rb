# frozen_string_literal: true

require 'rails_helper'

describe Barcode, type: :model do
  shared_examples 'a basic barcode' do
    describe '#human_barcode' do
      subject { barcode.human_barcode }
      it { is_expected.to eq human_barcode }
    end
    describe '#machine_barcode' do
      subject { barcode.machine_barcode }
      it { is_expected.to eq machine_barcode }
    end
  end

  shared_examples 'an ean13 barcode' do
    describe '#ean13_barcode?' do
      subject { barcode.ean13_barcode? }
      it { is_expected.to be true }
    end
    describe '#ean13_barcode' do
      subject { barcode.ean13_barcode }
      it { is_expected.to eq ean13_barcode }
    end
  end

  shared_examples 'a code128 barcode' do
    describe '#code128_barcode?' do
      subject { barcode.code128_barcode? }
      it { is_expected.to be true }
    end
    describe '#code128_barcode' do
      subject { barcode.code128_barcode }
      it { is_expected.to eq code128_barcode }
    end
  end

  context 'sanger_barcode' do
    let(:barcode) { create :sanger_ean13, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'DN12345U' }
    let(:barcode_format) { 'sanger_ean13' }
    let(:human_barcode) { 'DN12345U' }
    let(:machine_barcode) { '1220012345855' }
    let(:ean13_barcode) { '1220012345855' }
    let(:code128_barcode) { '1220012345855' }
    it_behaves_like 'a basic barcode'
    it_behaves_like 'an ean13 barcode'
    it_behaves_like 'a code128 barcode'
  end
end
