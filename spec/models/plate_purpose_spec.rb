# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe PlatePurpose do
  let(:plate_purpose) { create :plate_purpose, target_type:, size: }

  shared_examples 'a plate factory' do
    before { expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode)) }

    # rubocop:enable RSpec/ExpectInHook

    describe '#create!' do
      subject { plate_purpose.create! }

      it { is_expected.to be_a expected_plate_class }

      it 'builds a plate of the correct size' do
        expect(subject.size).to eq size
      end

      it 'sets itself as the purpose' do
        expect(subject.purpose).to eq(plate_purpose)
      end

      it 'creates wells' do
        expect(subject.wells.count).to eq size
      end
    end

    # Not a fan of this behaviour...
    # Essentially if any non hash argument is
    # passed in to plate creation it surpresses well
    # generation.
    describe '#create!(:without_wells)' do
      subject { plate_purpose.create!(:nope) }

      it 'does not create wells' do
        expect(subject.wells).to be_empty
      end
    end
  end

  context 'with a base class' do
    let(:target_type) { 'Plate' }
    let(:expected_plate_class) { Plate }
    let(:size) { 96 }

    it_behaves_like 'a plate factory'
  end

  context 'with a subclass' do
    let(:target_type) { 'WorkingDilutionPlate' }
    let(:expected_plate_class) { WorkingDilutionPlate }
    let(:size) { 384 }

    it_behaves_like 'a plate factory'
  end
end
