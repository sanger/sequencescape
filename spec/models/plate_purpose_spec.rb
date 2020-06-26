# frozen_string_literal: true

require 'rails_helper'

describe PlatePurpose, type: :model do
  let(:plate_purpose) { create :plate_purpose, prefix: barcode_prefix, target_type: target_type, size: size }

  shared_examples 'a plate factory' do
    setup do
      expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: 1000))
    end
    describe '#create!' do
      subject { plate_purpose.create! }

      it { is_expected.to be_a expected_plate_class }

      it 'set an appropriate barcode prefix' do
        human_barcode = subject.human_barcode
        matched = SBCF::HUMAN_BARCODE_FORMAT.match(human_barcode)
        expect(matched[:prefix]).to eq barcode_prefix
      end

      it 'builds a plate of the correct size' do # rubocop:todo RSpec/AggregateExamples
        expect(subject.size).to eq size
      end

      it 'sets itself as the purpose' do # rubocop:todo RSpec/AggregateExamples
        expect(subject.purpose).to eq(plate_purpose)
      end

      it 'creates wells' do # rubocop:todo RSpec/AggregateExamples
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
    let(:barcode_prefix) { 'DN' }
    let(:target_type) { 'Plate' }
    let(:expected_plate_class) { Plate }
    let(:size) { 96 }

    it_behaves_like 'a plate factory'
  end

  context 'with a subclass' do
    let(:barcode_prefix) { 'WD' }
    let(:target_type) { 'WorkingDilutionPlate' }
    let(:expected_plate_class) { WorkingDilutionPlate }
    let(:size) { 384 }

    it_behaves_like 'a plate factory'
  end
end
