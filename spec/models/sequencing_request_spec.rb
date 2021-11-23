# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencingRequest, type: :model do
  let(:library_tube) { create :library_tube }
  let(:sequencing_request) { create(:sequencing_request, asset: library_tube) }

  describe '#ready?' do
    subject { sequencing_request.ready? }

    context 'with a reception event' do
      before { library_tube.create_scanned_into_lab_event!(content: '2018-01-01') }

      context 'with no upstream requests as target' do
        it { is_expected.to be true }
      end

      context 'with empty assets' do
        let(:library_tube) { create :empty_library_tube }

        it { is_expected.to be false }
      end
    end

    context 'with no reception event' do
      context 'with missing assets' do
        let(:library_tube) { nil }

        it { is_expected.to be false }
      end

      context 'with no upstream requests as target' do
        it { is_expected.to be false }
      end
    end

    context 'with upstream requests' do
      before do
        library_tube.create_scanned_into_lab_event!(content: '2018-01-01')
        create :library_creation_request_for_testing_sequencing_requests,
               target_asset: library_tube,
               state: library_request_1_state
        create :library_creation_request_for_testing_sequencing_requests,
               target_asset: library_tube,
               state: library_request_2_state
      end

      # Nothing has happened yet!
      context 'which are both pending' do
        let(:library_request_1_state) { 'pending' }
        let(:library_request_2_state) { 'pending' }

        it { is_expected.to be false }
      end

      # Everything is AOkay!
      context 'which are passed' do
        let(:library_request_1_state) { 'passed' }
        let(:library_request_2_state) { 'passed' }

        it { is_expected.to be true }
      end

      # Most stuff is still in progress, so don't proceed
      context 'where one is pending, the other passed' do
        let(:library_request_1_state) { 'pending' }
        let(:library_request_2_state) { 'passed' }

        it { is_expected.to be false }
      end

      # Everything is completed, even is some stuff didn't work.
      # We're still good to go.
      context 'where one is passed, the other cancelled' do
        let(:library_request_1_state) { 'cancelled' }
        let(:library_request_2_state) { 'passed' }

        it { is_expected.to be true }
      end

      # Work is completed, but nothing worked.
      # Processing this would be a waste of time.
      context 'which are both cancelled' do
        let(:library_request_1_state) { 'cancelled' }
        let(:library_request_2_state) { 'cancelled' }

        it { is_expected.to be false }
      end
    end
  end

  describe '#loading_concentration' do
    subject { request.loading_concentration }

    let(:request) do
      create :complete_sequencing_request, event_descriptors: { 'Lane loading concentration (pM)' => user_input }
    end

    context 'with the expected input' do
      let(:user_input) { '20.5' }

      it { is_expected.to eq 20.5 }
    end

    context 'with an unnecessary but correct unit' do
      let(:user_input) { '20 pM' }

      it { is_expected.to eq 20.0 }
    end

    context 'with a wrong unit' do
      let(:user_input) { '20 nM' }

      # We don't convert, as a wrong unit shows a deviation from SOP, and possibly
      # indicated that the user has input the WRONG concentration

      it { is_expected.to eq nil }
    end

    context 'with unpredictable information' do
      let(:user_input) { '20 - 50 nM' }

      # Have some ranges in the database.

      it { is_expected.to eq nil }
    end

    context 'with lots of whitespace' do
      let(:user_input) { '  20    pM  ' }

      # Have some ranges in the database.

      it { is_expected.to eq 20.0 }
    end
  end

  # TODO: Feature Cardinal - Uncomment following:   
  # BEGIN: FEATURE CARDINAL 
  # context 'on start' do
  #   let(:samples) { create_list :sample, 2 }
  #   let(:study) { create :study, samples: samples }
  #   let(:destination) { create :receptacle }
  #   let(:source) { create :receptacle, aliquots: [aliquot1, aliquot2] }
  #   let(:library_tube) { create :library_tube, receptacles: [source] }
  #   let(:sequencing_request) { create(:sequencing_request, asset: source, target_asset: destination) }

  #   context 'when no tag_depth is defined in the source asset aliquots' do
  #     let(:aliquot1) { create :aliquot, sample: samples[0], tag_id: 1, study: study }
  #     let(:aliquot2) { create :aliquot, sample: samples[1], tag_id: 2, study: study }

  #     it 'performs a normal transfer of aliquots' do
  #       expect(sequencing_request.target_asset.aliquots.count).to eq(0)
  #       sequencing_request.start!
  #       expect(sequencing_request.target_asset.aliquots.count).to eq(source.aliquots.count)
  #       expect(sequencing_request.target_asset.samples.order(:id)).to eq(samples.sort)
  #     end
  #   end

  #   context 'when tag_depth is defined in the source asset aliquots' do
  #     let(:aliquot1) { create :aliquot, sample: samples[0], tag_depth: 1, study: study }
  #     let(:aliquot2) { create :aliquot, sample: samples[1], tag_depth: 2, study: study }

  #     it 'creates a compound sample and transfers an aliquot of it' do
  #       expect(sequencing_request.target_asset.aliquots.count).to eq(0)
  #       sequencing_request.start!
  #       expect(sequencing_request.target_asset.aliquots.count).to eq(1)
  #       expect(sequencing_request.target_asset.samples.first.component_samples.order(:id)).to eq(samples.sort)
  #     end
  #   end
  # end
  # END: FEATURE CARDINAL 
end
