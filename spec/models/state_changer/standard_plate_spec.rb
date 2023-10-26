# frozen_string_literal: true

require 'spec_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe StateChanger::StandardPlate do
  let(:state_changer) do
    described_class.new(
      labware: target_plate,
      target_state: target_state,
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    )
  end
  let(:user) { build_stubbed :user }
  let(:contents) { [] }
  let(:customer_accepts_responsibility) { false }

  describe '#update_labware_state' do
    context 'when the plate is the initial plate in the pipeline' do
      include_context 'a limber target plate with submissions', 'pending'

      let(:target_state) { 'started' }

      it 'starts the requests', :aggregate_failures do
        # Requests are started and we create one event per order.
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(1)
        expect(library_requests).to all(be_started)
      end
    end

    context 'when the plate is the initial plate in the pipeline but libraries are started' do
      include_context 'a limber target plate with submissions'

      let(:target_state) { 'started' }

      it 'starts the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
      end
    end

    context 'when the plate is cancelled at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'cancelled' }

      it 'does not cancel the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_passed)
      end
    end

    context 'when the plate is failed at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the plate is failed in the middle of the pipeline' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the customer accepts responsibility' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:customer_accepts_responsibility) { true }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        reloaded_library_requests = library_requests.each(&:reload)
        expect(reloaded_library_requests).to all(be_failed)
        expect(reloaded_library_requests).to all(be_customer_accepts_responsibility)
      end
    end

    context 'when a specific well is failed' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:contents) { ['A1'] } # This is the well that will be failed

      it 'allows failure of the specified requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        reloaded_library_requests = library_requests.each(&:reload)

        # A1 request should be failed
        expect(reloaded_library_requests.first).to be_failed

        # Other requests in B1 and C1 should be unchanged
        expect([reloaded_library_requests[1], reloaded_library_requests.last]).to all(be_started)
      end
    end

    context 'when a specific well is failed but the request is shared by other wells' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:samples) { create_list :sample, 2 }
      let(:study) { create :study, samples: samples }

      let(:library_request_type) { create :library_request_type }
      let(:submission_request_types) { [library_request_type] }

      # input plate
      let!(:input_plate) { create :plate }

      let(:input_aliquot1) { create :aliquot, sample: samples[0] }
      let(:input_aliquot2) { create :aliquot, sample: samples[1] }

      let!(:input_well1) do
        create :well, map: Map.find_by(description: 'A1'), plate: input_plate, aliquots: [input_aliquot1]
      end
      let!(:input_well2) do
        create :well, map: Map.find_by(description: 'B1'), plate: input_plate, aliquots: [input_aliquot2]
      end

      let(:request1) { create :library_request, asset: input_well1, submission: target_submission, state: 'started' }
      let(:request2) { create :library_request, asset: input_well2, submission: target_submission, state: 'started' }

      let!(:input_plate) { create :plate }

      # target plate
      let!(:target_plate) { create :plate }

      let(:target_aliquot1) { create :aliquot, sample: samples[0] }
      let(:target_aliquot2) { create :aliquot, sample: samples[0] }
      let(:target_aliquot3) { create :aliquot, sample: samples[1] }

      let!(:target_well1) do
        create :well, map: Map.find_by(description: 'A1'), plate: target_plate, aliquots: [target_aliquot1]
      end
      let!(:target_well2) do
        create :well, map: Map.find_by(description: 'B1'), plate: target_plate, aliquots: [target_aliquot2]
      end
      let!(:target_well3) do
        create :well, map: Map.find_by(description: 'C1'), plate: target_plate, aliquots: [target_aliquot3]
      end

      before do
        # need to reload plate to see wells in factory for creating requests
        input_plate.reload

        # set requests on aliquots
        input_well1.aliquots.first.update!(request: request1)
        input_well2.aliquots.first.update!(request: request2)

        target_plate.reload

        # stock well links TODO: do we need these?
        # target_well1.stock_well_links << build(:stock_well_link, target_well: target_well1, source_well: input_well1)

        # transfers from input plate A1 to two wells A1 and B1 in target plate
        create :transfer_request, asset: input_well1, target_asset: target_well1, outer_request: request1
        create :transfer_request, asset: input_well1, target_asset: target_well2, outer_request: request1

        # single transfer from input plate B1 to target plate C1
        create :transfer_request, asset: input_well2, target_asset: target_well3, outer_request: request2
      end

      context 'when the other wells are not failed' do
        let(:contents) { ['A1'] } # This well will be failed, but another well shares the request

        it 'prevents failure of the request', :aggregate_failures do
          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # No requests are failed
          expect(library_requests.each(&:reload)).to all(be_started)
        end
      end

      context 'when the other wells are also failed' do
        # This well will be failed, it shares a request with B1 that is already failed.
        let(:contents) { ['A1'] }

        before do
          # this should fail the request in B1, and cause target_well2 to have state failed
          target_well2.transfer_requests_as_target.first.transition_to('failed')
        end

        it 'fails the request', :aggregate_failures do
          # check target_well2 is in failed state as expected
          expect(target_well2.reload).to be_failed

          puts "DEBUG: request1 = #{request1.inspect}"
          puts "DEBUG: request2 = #{request2.inspect}"
          puts "DEBUG: submission = #{target_submission.inspect}"

          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # need to reload before checking state
          request1.reload
          request2.reload

          # A1 request should be failed
          expect(request1).to be_failed

          # Requests in C1 should be unchanged
          expect(request2).to be_started
        end
      end
    end
  end
end
