# frozen_string_literal: true

require 'rails_helper'
RSpec.describe TubeRack do
  describe '#create' do
    it 'can be created' do
      tube_rack = create(:tube_rack)

      expect(described_class.exists?(tube_rack.id)).to be(true)
    end

    it 'can contain racked_tubes' do
      tube_rack = create(:tube_rack)
      racked_tube = create(:racked_tube)

      expect { tube_rack.racked_tubes << racked_tube }.to(change { tube_rack.racked_tubes.count }.by(1))
    end

    it 'can contain a barcode' do
      tube_rack = create(:tube_rack)
      barcode = create(:barcode, barcode: 'SA00057843')

      tube_rack.barcodes << barcode

      expect(tube_rack.barcodes.last).to eq(barcode)
    end
  end

  describe '#update' do
    it 'can be updated' do
      tube_rack = create(:tube_rack)
      tube_rack.update(size: 96)

      expect(described_class.find(tube_rack.id).size).to eq(96)
    end
  end

  describe '#destroy' do
    let!(:tube_rack) { create(:tube_rack) }

    it 'can be destroyed' do
      tube_rack.destroy

      expect(described_class.exists?(tube_rack.id)).to be(false)
    end

    it 'destroys the RackedTubes when destroyed' do
      tube = Tube.create
      racked_tube = tube_rack.racked_tubes.create(tube_id: tube.id)

      tube_rack.destroy

      expect(RackedTube.exists?(racked_tube.id)).to be(false)
      expect(Tube.exists?(tube.id)).to be(true)
    end
  end

  describe '#state' do
    let(:class_with_state) do
      Class.new do
        attr_accessor :state

        def initialize(state)
          @state = state
        end
      end
    end

    let(:tube_rack) { create(:tube_rack) }

    context 'when there are no transfer requests' do
      it 'returns STATE_EMPTY' do
        allow(tube_rack).to receive(:transfer_requests_as_target).and_return([])
        expect(tube_rack.state).to eq(TubeRack::STATE_EMPTY)
      end
    end

    context 'when all transfer requests have the same state' do
      let(:tube_state) { 'pending' }
      let(:transfer_requests) do
        [class_with_state.new(tube_state), class_with_state.new(tube_state), class_with_state.new(tube_state)]
      end

      it 'returns the single state' do
        allow(tube_rack).to receive(:transfer_requests_as_target).and_return(transfer_requests)
        expect(tube_rack.state).to eq('pending')
      end
    end

    context 'when there are multiple states including states to filter out' do
      let(:tube1_state) { 'pending' }
      let(:tube2_state) { 'cancelled' }
      let(:tube3_state) { 'failed' }
      let(:transfer_requests) do
        [class_with_state.new(tube1_state), class_with_state.new(tube2_state), class_with_state.new(tube3_state)]
      end

      it 'returns the remaining state after filtering' do
        allow(tube_rack).to receive(:transfer_requests_as_target).and_return(transfer_requests)

        expect(tube_rack.state).to eq('pending')
      end
    end

    context 'when there are multiple states and filtering still results in multiple states' do
      let(:tube1_state) { 'pending' }
      let(:tube2_state) { 'started' }
      let(:tube3_state) { 'failed' }
      let(:transfer_requests) do
        [class_with_state.new(tube1_state), class_with_state.new(tube2_state), class_with_state.new(tube3_state)]
      end

      it 'returns STATE_MIXED' do
        allow(tube_rack).to receive(:transfer_requests_as_target).and_return(transfer_requests)
        expect(tube_rack.state).to eq(TubeRack::STATE_MIXED)
      end
    end
  end

  describe 'scope #contained_samples' do
    let(:num_tubes) { locations.length }
    let(:tube_rack) { create(:tube_rack) }
    let(:locations) { %w[A01 B01 C01] }
    let(:barcodes) { Array.new(num_tubes) { create(:fluidx) } }
    let!(:tubes) do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack, tube_rack: tube_rack, coordinate: locations[i], barcodes: [barcodes[i]])
      end
    end

    it 'returns the samples of the tubes contained in the rack' do
      expect(tube_rack.contained_samples.to_a.sort).to eq(tubes.map(&:samples).flatten.sort)
    end
  end

  context 'with a rack with tubes and requests' do
    let(:tube_rack) { create(:tube_rack) }
    let(:tube_a) { create(:tube, :in_a_rack, tube_rack: tube_rack, coordinate: 'A1') }
    let(:tube_b) { create(:tube, :in_a_rack, tube_rack: tube_rack, coordinate: 'H12') }
    let(:aliquot) { create(:aliquot, receptacle: tube_a.receptacle, request: create(:request, submission:)) }
    let(:outer_request) { create(:request, asset: tube_b.receptacle, submission: submission) }
    let(:submission) { create(:submission) }

    # The comments scope should also retrieve comments associated with tubes, and
    # their requests
    describe '#comments' do
      let!(:rack_comment) { create(:comment, commentable: tube_rack, title: 'Rack') }
      let!(:tube_comment) { create(:comment, commentable: tube_a, title: 'Tube') }
      let!(:request_comment_a) { create(:comment, commentable: aliquot.request, title: 'Request(Aliquot)') }
      let!(:request_comment_b) { create(:comment, commentable: outer_request, title: 'Request(Receptacle)') }

      it 'includes all relevant comments' do
        comments = tube_rack.reload.comments

        aggregate_failures do
          expect(comments).to include(rack_comment)
          expect(comments).to include(tube_comment)
          expect(comments).to include(request_comment_a)
          expect(comments).to include(request_comment_b)
        end
      end
    end

    # This is called following comment addition
    describe '#after_comment_addition' do
      context 'with submissions' do
        before { outer_request }

        it 'ensures comments are visible on the tubes' do
          create(:comment, commentable: tube_rack)
          expect(tube_b.reload.comments.count).to eq 1
        end
      end

      context 'without submissions' do
        before { tube_b }

        it 'ensures comments are visible on the tubes' do
          create(:comment, commentable: tube_rack)
          expect(tube_b.reload.comments.count).to eq 1
        end
      end
    end
  end
end
