# frozen_string_literal: true

require 'rails_helper'

describe Tube::Purpose do
  let(:tube_purpose) { create(:tube_purpose, prefix: barcode_prefix, target_type:) }

  shared_examples 'a tube factory' do
    describe '#create!' do
      subject { tube_purpose.create! }

      it { is_expected.to be_a expected_tube_class }

      it 'set an appropriate barcode prefix' do
        expect(subject.primary_barcode.prefix.human).to eq barcode_prefix
      end

      it 'sets itself as the purpose' do
        expect(subject.purpose).to eq(tube_purpose)
      end
    end
  end

  context 'with a base class' do
    let(:barcode_prefix) { 'NT' }
    let(:target_type) { 'SampleTube' }
    let(:expected_tube_class) { SampleTube }

    it_behaves_like 'a tube factory'
  end

  context 'with a subclass' do
    let(:barcode_prefix) { 'NT' }
    let(:target_type) { 'LibraryTube' }
    let(:expected_tube_class) { LibraryTube }

    it_behaves_like 'a tube factory'
  end
end
