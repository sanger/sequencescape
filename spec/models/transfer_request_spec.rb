# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe TransferRequest, type: :model do
  let(:source) { create :well_with_sample_and_without_plate }
  let(:tag) { create(:tag).tag!(source) }
  let(:destination) { create :well }
  let(:example_study) { create :study }
  let(:example_project) { create :project }

  context 'with a library request' do
    subject do
      create :transfer_request,
             asset: source,
             target_asset: destination,
             submission: library_request.submission
    end

    let(:library_request) do
      create :library_request,
             asset: source,
             initial_study: example_study,
             initial_project: example_project,
             state: library_state
    end

    context 'with a pending library request' do
      let(:library_state) { 'pending' }

      it 'sets the target aliquots to the library request study and project' do
        subject
        expect(destination.aliquots.first.study).to eq(example_study)
        expect(destination.aliquots.first.project).to eq(example_project)
      end

      it 'sets appropriate metadata on the aliquots' do
        subject
        expect(destination.aliquots.first.library_type).to eq(library_request.library_type)
        expect(destination.aliquots.first.insert_size).to eq(library_request.insert_size)
      end

      it 'starts the library request when started' do
        subject.start!
        expect(library_request.reload.state).to eq('started')
      end

      # Users can jump straight to passed from pending. So we need to handle that as well.
      it 'starts the library request when passed' do
        subject.pass!
        expect(library_request.reload.state).to eq('started')
      end
    end

    context 'with a started outer request' do
      let(:library_state) { 'started' }

      it 'transitions without changing the library request' do
        subject.pass!
        expect(library_request.reload.state).to eq('started')
      end
    end
  end

  context 'TransferRequest' do
    context 'when using the constuctor' do
      let!(:transfer_request) { TransferRequest.create!(asset: source, target_asset: destination) }

      it 'should duplicate the aliquots' do
        expected_aliquots = source.aliquots.map { |a| [a.sample_id, a.tag_id] }
        target_aliquots   = destination.aliquots.map { |a| [a.sample_id, a.tag_id] }
        expect(target_aliquots).to eq expected_aliquots
      end

      it 'should have the correct attributes' do
        expect(transfer_request.state).to eq 'pending'
        expect(transfer_request.asset_id).to eq source.id
        expect(transfer_request.target_asset_id).to eq destination.id
      end
    end

    it 'should not permit transfers to the same asset' do
      asset = create(:sample_tube)
      expect { TransferRequest.create!(asset: asset, target_asset: asset) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'with a tag clash' do
      let!(:tag) { create :tag }
      let!(:tag2) { create :tag }
      let!(:aliquot_1) { create :aliquot, tag: tag, tag2: tag2 }
      let!(:aliquot_2) { create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well) }
      let!(:target_asset) { create :well, aliquots: [aliquot_1] }

      it 'should raise an exception' do
        expect do
          TransferRequest.create!(asset: aliquot_2.receptacle.reload, target_asset: target_asset)
        end.to raise_error(Aliquot::TagClash)
      end
    end
  end

  describe 'state_machine' do
    subject { build :transfer_request }

    {
      start: { pending: :started },
      pass: { pending: :passed, started: :passed, failed: :passed, processed_2: :passed },
      process_1: { pending: :processed_1 },
      process_2: { processed_1: :processed_2 },
      qc: { passed: :qc_complete },
      fail: { pending: :failed, started: :failed, processed_1: :failed, processed_2: :failed, passed: :failed },
      cancel: { started: :cancelled, processed_1: :cancelled, processed_2: :cancelled, passed: :cancelled, qc_complete: :cancelled },
      cancel_before_started: { pending: :cancelled }
    }.each do |event, transitions|
      transitions.each do |from_state, to_state|
        it { is_expected.to transition_from(from_state).to(to_state).on_event(event) }
      end
      (%i[pending started passed failed qc_complete cancelled] - transitions.keys).each do |state|
        it "does not allow #{state} requests to #{event}" do
          tf = build :transfer_request, state: state
          expect(tf).to_not allow_event(event)
        end
      end
    end
  end

  context 'outer request' do
    let(:last_well) { create :well_with_sample_and_without_plate }
    let(:example_study) { create :study }
    let(:example_project) { create :project }

    let(:library_request) do
      create :library_request,
             asset: stock_asset
    end

    before do
      # A decoy library request, this is part of a different submission and
      # should be ignored
      create :library_request, asset: stock_asset
      last_well.stock_wells << stock_asset
    end

    let(:transfer_request) do
      create :transfer_request, asset: source_asset, submission: library_request.submission
    end

    describe '#outer_request' do
      subject { transfer_request.outer_request }

      context 'from a stock asset' do
        let(:source_asset) { last_well }
        let(:stock_asset) { source_asset }
        it { is_expected.to eq library_request }
      end

      context 'from a well downstream of a stock asset' do
        let(:source_asset) { last_well }
        let(:stock_asset) { create :well_with_sample_and_without_plate }
        it { is_expected.to eq library_request }
      end

      context 'from a tube made from the last well' do
        let(:stock_asset) { create :well_with_sample_and_without_plate }
        let(:source_asset) { create :tube }
        before { create :transfer_request, asset: last_well, target_asset: source_asset }
        it { is_expected.to eq library_request }
      end
    end
  end
end
