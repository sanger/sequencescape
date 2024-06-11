# frozen_string_literal: true

require 'rails_helper'

context 'printing different asset types' do
  shared_examples 'a correct filter' do
    subject { described_class.new(options).assets }

    describe 'from asset group controller' do
      let(:options) do
        { printables: { asset1.id.to_s => 'true', asset2.id.to_s => 'true', asset3.id.to_s => 'false' } }
      end

      it { is_expected.to eq [asset1, asset2] }
    end

    describe 'from asset controller #print_assets' do
      let(:options) { { printables: asset1 } }

      it { is_expected.to eq [asset1] }
    end
  end

  shared_examples 'a correct plate renderer' do
    subject { described_class.new(options).labels.count }

    context 'printing single label' do
      let(:options) { { printables: asset1, printer_type_class: BarcodePrinterType } }

      it { is_expected.to eq 1 }
    end

    context 'printing double label' do
      let(:options) { { printables: asset1, printer_type_class: BarcodePrinterType384DoublePlate } }

      it { is_expected.to eq 2 }
    end
  end

  shared_examples 'a correct tube renderer' do
    subject { described_class.new(options).labels.first }

    context 'printing tube' do
      let(:options) { { printables: asset1 } }

      it { is_expected.to have_key(:round_label_top_line) }
    end
  end

  describe LabelPrinter::Label::AssetRedirect do
    context 'printing plates' do
      let(:asset1) { create(:child_plate) }
      let(:asset2) { create(:child_plate) }
      let(:asset3) { create(:child_plate) }

      it_behaves_like 'a correct filter'
      it_behaves_like 'a correct plate renderer'
    end

    context 'printing tubes' do
      let(:asset1) { create(:empty_sample_tube) }
      let(:asset2) { create(:empty_sample_tube) }
      let(:asset3) { create(:empty_sample_tube) }

      it_behaves_like 'a correct filter'
      it_behaves_like 'a correct tube renderer'
    end
  end
end
