# frozen_string_literal: true

require 'rails_helper'

describe Barcode do
  shared_examples 'a basic barcode' do
    describe '#human_barcode' do
      subject { barcode.human_barcode }

      it { is_expected.to eq human_barcode }
    end

    describe '#machine_barcode' do
      subject { barcode.machine_barcode }

      it { is_expected.to eq machine_barcode }
    end

    describe 'valid?' do
      before { create(:barcode, barcode: barcode_value, format: barcode_format) }

      it 'is invalid if it is duplicated' do
        expect(barcode).not_to be_valid
      end
    end
  end

  shared_examples 'a composable barcode' do
    describe '#barcode_number' do
      subject { barcode.number }

      it { is_expected.to eq number }
    end

    describe '#barcode_prefix' do
      subject { barcode.barcode_prefix }

      it { is_expected.to eq barcode_prefix }
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

  shared_examples 'not an ean13 barcode' do
    describe '#ean13_barcode?' do
      subject { barcode.ean13_barcode? }

      it { is_expected.to be false }
    end

    describe '#ean13_barcode' do
      subject { barcode.ean13_barcode }

      it { is_expected.to be_nil }
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

  shared_examples 'a code39 barcode' do
    describe '#code39_barcode?' do
      subject { barcode.code39_barcode? }

      it { is_expected.to be true }
    end

    describe '#code39_barcode' do
      subject { barcode.code39_barcode }

      it { is_expected.to eq code39_barcode }
    end
  end

  context 'Adding labware association' do
    let(:barcode_value) { 'DN12345U' }
    let(:barcode_format) { 'sanger_ean13' }
    let(:barcode) { build :sanger_ean13, barcode: barcode_value, format: barcode_format }

    before do
      barcode.save!
    end

    it 'has an asset' do
      expect(barcode.labware).to be_a Labware
    end

    it 'has one asset' do
      expect(Labware.find(barcode.reload.asset_id)).not_to be_nil
      expect(Labware.all.count).to eq 1
    end

  end

  shared_examples 'not a code39 barcode' do
    describe '#code39_barcode?' do
      subject { barcode.code39_barcode? }

      it { is_expected.to be false }
    end

    describe '#code39_barcode' do
      subject { barcode.code39_barcode }

      it { is_expected.to be_nil }
    end
  end

  context 'sanger_ean13' do
    let(:barcode) { build :sanger_ean13, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'DN12345U' }
    let(:number) { 12_345 }
    let(:barcode_prefix) { 'DN' }
    let(:suffix) { 'U' }
    let(:barcode_format) { 'sanger_ean13' }
    let(:human_barcode) { 'DN12345U' }
    let(:machine_barcode) { '1220012345855' }
    let(:ean13_barcode) { '1220012345855' }
    let(:code128_barcode) { '1220012345855' }
    let(:code39_barcode) { '1220012345855' }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'an ean13 barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    it 'is valid' do
      expect(barcode).to be_valid
    end

    context 'with an incompatible format' do
      let(:barcode_value) { 'notabarcode' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end
  end

  context 'sanger_code39' do
    let(:barcode) { build :sanger_code39, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'DN12345U' }
    let(:number) { 12_345 }
    let(:barcode_prefix) { 'DN' }
    let(:suffix) { 'U' }
    let(:barcode_format) { 'sanger_code39' }
    let(:human_barcode) { 'DN12345U' }
    let(:machine_barcode) { 'DN12345U' }
    let(:ean13_barcode) { '1220012345855' }
    let(:code128_barcode) { 'DN12345U' }
    let(:code39_barcode) { 'DN12345U' }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'an ean13 barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    it 'is valid' do
      expect(barcode).to be_valid
    end

    context 'with an incompatible format' do
      let(:barcode_value) { 'notabarcode' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end
  end

  context 'sequencescape22' do
    let(:barcode) { build :sequencescape22, barcode: barcode_value, format: barcode_format }
    let(:barcode_value) { 'SQPD-12345' }
    let(:barcode_format) { 'sequencescape22' }
    let(:number) { 12_345 }
    let(:barcode_prefix) { 'SQPD' }
    let(:human_barcode) { 'SQPD-12345' }
    let(:machine_barcode) { 'SQPD-12345' }
    let(:ean13_barcode) { nil }
    let(:code128_barcode) { 'SQPD-12345' }
    let(:code39_barcode) { 'SQPD-12345' }
    let(:sequencescape22_barcode) { 'SQPD-12345' }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    it 'is valid' do
      expect(barcode).to be_valid
    end

    context 'with an incompatible format' do
      let(:barcode_value) { 'INVALID-123' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end

    context 'with an baracoda child barcode format' do
      let(:barcode_value) { 'SQPD-12345-5' }

      it 'is not valid' do
        expect(barcode).to be_valid
      end
    end
  end

  context 'infinium' do
    let(:barcode) { build :infinium, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'WG0010602-DNA' }
    let(:barcode_format) { 'infinium' }
    let(:number) { 10_602 }
    let(:barcode_prefix) { 'WG' }
    let(:suffix) { 'DNA' }
    let(:human_barcode) { 'WG0010602-DNA' }
    let(:machine_barcode) { 'WG0010602-DNA' }
    let(:code128_barcode) { 'WG0010602-DNA' }
    let(:code39_barcode) { 'WG0010602-DNA' }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    context 'with an incompatible format' do
      let(:barcode_value) { 'notabarcode' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end
  end

  context 'fluidigm' do
    let(:barcode) { build :fluidigm, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { '1662051218' }
    let(:barcode_format) { 'fluidigm' }
    let(:human_barcode) { '1662051218' }
    let(:machine_barcode) { '1662051218' }
    let(:code128_barcode) { '1662051218' }
    let(:code39_barcode) { '1662051218' }
    let(:prefix) { nil }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    context 'with an incompatible format' do
      let(:barcode_value) { 'notabarcode' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end
  end

  context 'uk biocentre v3' do
    let(:barcode) { build :external, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'RNA12345' }
    let(:barcode_format) { 'uk_biocentre_v3' }
    let(:number) { 12_345 }
    let(:barcode_prefix) { 'RNA' }
    let(:suffix) { nil }
    let(:human_barcode) { 'RNA12345' }
    let(:machine_barcode) { 'RNA12345' }
    let(:code128_barcode) { 'RNA12345' }
    let(:code39_barcode) { 'RNA12345' }
    let(:prefix) { 'RNA' }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'

    context 'with an incompatible format' do
      let(:barcode_value) { 'notabarcode' }

      it 'is not valid' do
        expect(barcode).not_to be_valid
      end
    end
  end

  context 'external' do
    let(:barcode) { build :external, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'EXT_135432_D' }
    let(:barcode_format) { 'external' }
    let(:number) { 135_432 }
    let(:barcode_prefix) { 'EXT_' }
    let(:suffix) { '_D' }
    let(:human_barcode) { 'EXT_135432_D' }
    let(:machine_barcode) { 'EXT_135432_D' }
    let(:code128_barcode) { 'EXT_135432_D' }
    let(:prefix) { nil }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'not a code39 barcode'
  end

  context 'external - odd format' do
    let(:barcode) { build :external, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'Q123RT12E45' }
    let(:barcode_format) { 'external' }
    let(:number) { nil }
    let(:barcode_prefix) { nil }
    let(:suffix) { nil }
    let(:human_barcode) { 'Q123RT12E45' }
    let(:machine_barcode) { 'Q123RT12E45' }
    let(:code128_barcode) { 'Q123RT12E45' }
    let(:code39_barcode) { 'Q123RT12E45' }
    let(:prefix) { nil }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'
  end

  context 'foreign - CGAP format' do
    let(:barcode) { build :cgap, barcode: barcode_value, format: barcode_format }

    let(:barcode_value) { 'CGAP-ABC123' }
    let(:barcode_format) { 'cgap' }
    let(:number) { 'ABC12' }
    let(:barcode_prefix) { 'CGAP-' }
    let(:suffix) { '3' }
    let(:human_barcode) { 'CGAP-ABC123' }
    let(:machine_barcode) { 'CGAP-ABC123' }
    let(:code128_barcode) { 'CGAP-ABC123' }
    let(:code39_barcode) { 'CGAP-ABC123' }
    let(:prefix) { nil }

    let(:summary) { { number: 'ABC12', prefix: 'CGAP-', machine_barcode: 'CGAP-ABC123' } }

    it_behaves_like 'a basic barcode'
    it_behaves_like 'not an ean13 barcode'
    it_behaves_like 'a composable barcode'
    it_behaves_like 'a code128 barcode'
    it_behaves_like 'a code39 barcode'
  end
end
