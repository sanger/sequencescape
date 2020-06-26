# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe WorkCompletion do
  include_context 'a limber target plate with submissions'

  describe '::create' do
    context 'with a cross-submission tube' do
      before do
        described_class.create!(
          user: create(:user),
          target: target_tube
        )
      end

      let(:submission_request_types) { [library_request_type] }

      let(:target_tube) do
        tt = create :multiplexed_library_tube
        tt.parents << upstream_tube
        create :transfer_request, asset: upstream_tube, target_asset: tt
        tt
      end

      let(:upstream_tube) do
        ut = create :new_stock_multiplexed_library_tube, purpose: create(:mixed_submission_mx)
        [target_plate, target_plate2].each do |plate|
          plate.wells.each do |well|
            create :transfer_request, asset: well, target_asset: ut
          end
        end
        ut.parents = [target_plate, target_plate2]
        ut
      end

      let(:target_plate2) do
        build_library_requests2
        create :target_plate, parent: input_plate2, well_count: tested_wells, submission: target_submission2
      end
      let(:input_plate2) { create :input_plate, well_count: tested_wells, well_factory: :tagged_well }
      let(:build_library_requests2) do
        input_plate2.wells.each do |well|
          create_list :library_request, requests_per_well, request_type: library_request_type, asset: well, submission: target_submission2, state: 'started'
        end
      end
      let(:target_submission2) do
        create :library_submission, assets: input_plate2.wells, request_types: submission_request_types
      end

      let(:library_requests_submission2) { target_submission2.requests.where(request_type_id: library_request_type.id) }

      let(:all_library_requests) do
        library_requests + library_requests_submission2
      end

      let(:all_multiplex_requests) do
        multiplex_requests + multiplex_requests_submission2
      end

      it 'has built correctly' do
        # If the submission isn't correctly built, we'll get misleading passes/failures
        expect(library_requests.count).to eq(tested_wells)
      end

      it 'passes the library requests' do # rubocop:todo RSpec/AggregateExamples
        expect(all_library_requests).to all(be_passed)
      end

      it 'does not pass the decoy submission' do # rubocop:todo RSpec/AggregateExamples
        expect(decoy_submission_requests).to all(be_started)
      end

      it 'joins up the library requests' do
        library_requests.each do |request|
          expect(request.target_asset).to eq(target_tube.receptacle)
        end
      end
    end

    context 'with additional requests' do
      let(:requests_per_well) { 2 }

      before do
        described_class.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      let(:decoy_requests) { input_plate.wells.flat_map { |w| w.requests[1, 2].map(&:reload) } }
      let(:library_requests) { input_plate.wells.map { |w| w.requests.first.reload } }

      it 'passes the library requests' do
        expect(library_requests).to all(be_passed)
      end

      it 'does not pass the multiplex requests' do # rubocop:todo RSpec/AggregateExamples
        expect(multiplex_requests).to all(be_pending)
      end

      it 'does not pass the decoy requests' do # rubocop:todo RSpec/AggregateExamples
        expect(decoy_requests).to all(be_started)
      end
    end

    context 'without failed wells' do
      before do
        # We'll keep things simple for the moment.
        # Note: We explicitly pass in submission. Not only will this allow partial passing of plates,
        # but will also reduce coupling with transfer requests, and help push business logic out into
        # the client applications.
        described_class.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      it 'has built correctly' do
        # If the submission isn't correctly built, we'll get misleading passes/failures
        expect(library_requests.count).to eq(tested_wells)
      end

      it 'passes the library requests' do # rubocop:todo RSpec/AggregateExamples
        expect(library_requests).to all(be_passed)
      end

      it 'does not pass the multiplex requests' do # rubocop:todo RSpec/AggregateExamples
        expect(multiplex_requests).to all(be_pending)
      end

      it 'does not pass the decoy submission' do # rubocop:todo RSpec/AggregateExamples
        expect(decoy_submission_requests).to all(be_started)
      end

      it 'joins up the library requests' do
        library_requests.each do |request|
          expect(request.target_asset).not_to be_nil
          expect(request.target_asset.plate).to eq(target_plate)
          expect(request.target_asset.map_description).to eq(request.asset.map_description)
        end
      end

      it 'joins up the multiplex requests' do # rubocop:todo RSpec/AggregateExamples
        expect(multiplex_requests.map(&:asset).uniq.size).to eq(tested_wells)
      end

      it 'sets up any wells as their own stock wells' do
        target_plate.wells.each do |well|
          expect(well.stock_wells).to include(well)
        end
      end
    end

    context 'when wells are failed' do
      before do
        library_requests.first.fail!
        described_class.create!(
          user: create(:user),
          target: target_plate,
          submissions: [target_submission]
        )
      end

      it "doesn't pass the failed request" do
        expect(library_requests.first).to be_failed
      end
    end

    context 'when no submission is included' do
      before do
        described_class.create!(
          user: create(:user),
          target: target_plate,
          submissions: []
        )
      end

      it "doesn't pass the request" do
        expect(library_requests.first).to be_started
      end
    end
  end
end
