# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

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

  describe '#transition_to' do
    let(:user) { create :user }

    context 'when the plate is the initial plate in the pipeline' do
      include_context 'a limber target plate with submissions', 'pending'
      it 'starts the requests', :aggregate_failures do
        # Requests are started and we create one event per order.
        expect do
          target_plate.plate_purpose.transition_to(target_plate, 'started', user)
        end.to change(BroadcastEvent::LibraryStart, :count).by(1)
        expect(library_requests).to all(be_started)
      end
    end

    context 'when the plate is the initial plate in the pipeline but libraries are started' do
      include_context 'a limber target plate with submissions'
      it 'starts the requests', :aggregate_failures do
        expect do
          target_plate.plate_purpose.transition_to(target_plate, 'started', user)
        end.to change(BroadcastEvent::LibraryStart, :count).by(0)
      end
    end

    context 'when the plate is at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }

      it 'does not cancel the requests', :aggregate_failures do
        expect do
          target_plate.plate_purpose.transition_to(target_plate, 'cancelled', user)
        end.to change(BroadcastEvent::LibraryStart, :count).by(0)
        expect(library_requests.each(&:reload)).to all(be_passed)
      end

      it 'does allow failure of the requests', :aggregate_failures do
        expect do
          target_plate.plate_purpose.transition_to(target_plate, 'failed', user)
        end.to change(BroadcastEvent::LibraryStart, :count).by(0)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end
  end
end
