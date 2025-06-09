# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe TransferRequest do
  let(:source) { create(:well_with_sample_and_without_plate) }
  let(:tag) { create(:tag).tag!(source) }
  let(:destination) { create(:well) }
  let(:example_study) { create(:study) }
  let(:example_project) { create(:project) }

  context 'with a library request' do
    subject do
      create(:transfer_request, asset: source, target_asset: destination, submission: library_request.submission)
    end

    let(:library_request) do
      create(
        :library_request,
        asset: source,
        initial_study: example_study,
        initial_project: example_project,
        state: library_state
      )
    end

    context 'with volume' do
      subject do
        create(
          :transfer_request,
          asset: source,
          target_asset: destination,
          submission: library_request.submission,
          volume: 4.5
        )
      end

      let(:library_state) { 'pending' }

      it 'records the volume' do
        expect(subject.volume).to eq(4.5)
      end
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

    context 'with a primer panel' do
      let(:library_request) do
        create(
          :gbs_request,
          state: 'pending',
          asset: source,
          initial_study: example_study,
          initial_project: example_project
        )
      end

      it 'sets appropriate metadata on the aliquots' do
        subject
        expect(destination.aliquots.first.library_type).to eq(library_request.library_type)
        expect(destination.aliquots.first.insert_size).to eq(library_request.insert_size)
        expect(destination.aliquots.first.primer_panel).to eq(library_request.primer_panel)
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

  context 'with multiple library requests' do
    subject { create(:transfer_request, asset: source, target_asset: destination, outer_request: library_request) }

    before do
      library_request
      dummy_library_request
    end

    let(:library_request) do
      create(
        :library_request,
        asset: source,
        initial_study: example_study,
        initial_project: example_project,
        state: library_state
      )
    end

    let(:dummy_library_request) do
      create(
        :library_request,
        asset: source,
        initial_study: example_study,
        initial_project: example_project,
        state: library_state,
        submission: library_request.submission
      )
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

      it 'does not starts the dummy library request when started' do
        subject.start!
        expect(dummy_library_request.reload.state).to eq('pending')
      end

      # Users can jump straight to passed from pending. So we need to handle that as well.
      it 'starts the library request when passed' do
        subject.pass!
        expect(library_request.reload.state).to eq('started')
      end
    end
  end

  context 'TransferRequest' do
    context 'when using the constuctor' do
      let!(:transfer_request) { described_class.create!(asset: source, target_asset: destination) }

      it 'duplicates the aliquots' do
        expected_aliquots = source.aliquots.map { |a| [a.sample_id, a.tag_id] }
        target_aliquots = destination.aliquots.map { |a| [a.sample_id, a.tag_id] }
        expect(target_aliquots).to eq expected_aliquots
      end

      it 'has the correct attributes' do
        expect(transfer_request.state).to eq 'pending'
        expect(transfer_request.asset_id).to eq source.id
        expect(transfer_request.target_asset_id).to eq destination.id
      end

      context 'when the source has stock wells' do
        let(:source) { create(:well_with_sample_and_without_plate, stock_wells: create_list(:well, 2)) }

        it 'sets the stock wells' do
          expect(destination.stock_wells).to eq(source.stock_wells)
        end
      end

      context 'when the source is a stock well' do
        let(:source) { create(:well_with_sample_and_without_plate, plate: create(:stock_plate)) }

        it 'sets the stock wells' do
          expect(destination.stock_wells).to eq([source])
        end
      end
    end

    context 'when building using tag_depth' do
      context 'when building several transfer requests' do
        let(:transfer_request) do
          described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 1 })
        end

        context 'with the same tag depth' do
          let(:transfer_request2) do
            described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 1 })
          end

          it 'cannot create several requests into the same destination' do
            expect { [transfer_request, transfer_request2] }.to raise_error Aliquot::TagClash
          end
        end

        context 'with the different tag depth' do
          let(:transfer_request2) do
            described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 2 })
          end

          it 'can create several requests into the same destination, allowing tag clash' do
            expect { [transfer_request, transfer_request2] }.not_to raise_error
          end
        end
      end
    end

    context 'when the destination has equivalent aliquots' do
      let(:equivalent_aliquot) { source.aliquots.first.dup }
      let(:destination) { create(:well, aliquots: [equivalent_aliquot]) }
      let(:transfer_request) do
        described_class.new(asset: source, target_asset: destination, merge_equivalent_aliquots: merge)
      end

      context 'when merge_equivalent_aliquots is true' do
        let(:merge) { true }

        it 'will create a transfer request and merge aliquots' do
          expect(transfer_request.save).to be true
          expect(destination.aliquots.reload).to have(1).item
        end
      end

      context 'when merge_equivalent_aliquots is false' do
        let(:merge) { false }

        it 'will throw a TagClash exception' do
          expect { transfer_request.save }.to raise_error(Aliquot::TagClash) do |error|
            expect(error.api_error_code).to eq(422)
          end
        end
      end
    end

    it 'does not permit transfers to the same asset' do
      asset = create(:sample_tube)
      expect { described_class.create!(asset: asset, target_asset: asset) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'with a tag clash' do
      let!(:tag) { create(:tag) }
      let!(:tag2) { create(:tag) }
      let!(:aliquot_1) { create(:aliquot, tag:, tag2:) }
      let!(:aliquot_2) { create(:aliquot, tag: tag, tag2: tag2, receptacle: create(:well)) }
      let!(:target_asset) { create(:well, aliquots: [aliquot_1]) }

      it 'raises an exception' do
        expect do
          described_class.create!(asset: aliquot_2.receptacle.reload, target_asset: target_asset)
        end.to raise_error(Aliquot::TagClash)
      end
    end
  end

  describe 'state_machine' do
    subject { create(:transfer_request) }

    {
      start: {
        pending: :started
      },
      pass: {
        pending: :passed,
        started: :passed,
        failed: :passed,
        processed_2: :passed,
        processed_3: :passed,
        processed_4: :passed
      },
      process_1: {
        pending: :processed_1
      },
      process_2: {
        processed_1: :processed_2
      },
      process_3: {
        processed_2: :processed_3
      },
      process_4: {
        processed_3: :processed_4
      },
      qc: {
        passed: :qc_complete
      },
      fail: {
        pending: :failed,
        started: :failed,
        processed_1: :failed,
        processed_2: :failed,
        processed_3: :failed,
        processed_4: :failed,
        passed: :failed
      },
      cancel: {
        started: :cancelled,
        processed_1: :cancelled,
        processed_2: :cancelled,
        processed_3: :cancelled,
        processed_4: :cancelled,
        passed: :cancelled,
        qc_complete: :cancelled
      },
      cancel_before_started: {
        pending: :cancelled
      }
    }.each do |event, transitions|
      transitions.each do |from_state, to_state|
        it { is_expected.to transition_from(from_state).to(to_state).on_event(event) }
      end
      (%i[pending started passed failed qc_complete cancelled] - transitions.keys).each do |state|
        it "does not allow #{state} requests to #{event}" do
          tf = build(:transfer_request, state:)
          expect(tf).not_to allow_event(event)
        end
      end
    end
  end

  context 'outer request' do
    let(:last_well) { create(:well_with_sample_and_without_plate) }
    let(:example_study) { create(:study) }
    let(:example_project) { create(:project) }

    let(:library_request) { create(:library_request, asset: stock_asset, submission: create(:submission)) }

    before do
      # A decoy library request, this is part of a different submission and
      # should be ignored
      create(:library_request, asset: stock_asset, submission: create(:submission))
      last_well.stock_wells << stock_asset
    end

    let(:transfer_request) { create(:transfer_request, asset: source_asset, submission: library_request.submission) }

    describe '#outer_request' do
      subject { transfer_request.outer_request }

      context 'from a stock asset' do
        let(:source_asset) { last_well }
        let(:stock_asset) { source_asset }

        it { is_expected.to eq library_request }
      end

      context 'from a well downstream of a stock asset' do
        let(:source_asset) { last_well }
        let(:stock_asset) { create(:well_with_sample_and_without_plate) }

        it { is_expected.to eq library_request }
      end

      context 'from a tube made from the last well' do
        let(:stock_asset) { create(:well_with_sample_and_without_plate) }
        let(:source_asset) { create(:tube) }

        before do
          create(
            :transfer_request,
            asset: last_well,
            target_asset: source_asset,
            submission: library_request.submission
          )
        end

        it { is_expected.to eq library_request }
      end
    end
  end

  context 'when failing a transfer request with downstream assets' do
    # Labware
    let(:original_plate) { create(:plate_with_untagged_wells, well_count: 1) }
    let(:original_well) { original_plate.wells.first }
    let(:plates) { create_list(:plate, 3, well_count: 1) }
    let(:wells) { plates.map(&:wells).flatten }
    let(:assets) { [original_well, wells].flatten }

    # Requests
    let!(:outer_requests_graph) do
      [
        create(:library_creation_request, asset: original_well, target_asset: wells[0]),
        create(:multiplexed_library_creation_request, asset: wells[0], target_asset: wells[1]),
        create(:sequencing_request, asset: wells[1], target_asset: wells[2])
      ]
    end
    let!(:transfer_requests) do
      [
        create(:transfer_request, asset: original_well, target_asset: wells[0]),
        create(:transfer_request, asset: wells[0], target_asset: wells[1]),
        create(:transfer_request, asset: wells[1], target_asset: wells[2])
      ]
    end

    before do
      # We build the submission and add the requests to it
      create(:submission, requests: outer_requests_graph)

      # We modify the receptacles so the reference the right outer request in each step of the path
      original_well.aliquots.first&.update(request: outer_requests_graph[0])
      wells[0].aliquots.first&.update(request: outer_requests_graph[1])
      wells[1].aliquots.first&.update(request: outer_requests_graph[2])

      # We create an asset link between the multiplexing and the start of sequencing
      create(:asset_link, ancestor: wells[1].plate, descendant: wells[2].plate)
    end

    context 'when any of the downstream assets have a batch' do
      let(:batch) { create(:sequencing_batch, request_count: 1) }

      before { outer_requests_graph[2].update(batch:) }

      it 'does not remove the downstream aliquots' do
        expect { transfer_requests.first.fail! }.not_to change {
          Delayed::Worker.new.work_off
          assets[2..].map { |a| a.aliquots.count }.uniq
        }.from([1])
      end
    end

    context 'when none of the downstream assets have a batch' do
      it 'removes the downstream aliquots' do
        # checking that the count of unique aliquot counts changes from [1] to [0] when the fail!
        # method is called on the first transfer request. In other words, it's expecting that all downstream assets
        # initially have one aliquot, and that they have zero aliquots after the transfer request is failed.
        expect { transfer_requests.first.fail! }.to change {
          Delayed::Worker.new.work_off
          assets[2..].map { |a| a.aliquots.count }.uniq
        }.from([1]).to([0])
      end
    end
  end

  context 'transfer downstream of pooling (such as in ISC)' do
    let(:library_request_type) { create(:library_request_type) }
    let(:multiplex_request_type) { create(:multiplex_request_type) }

    # In some cases (such as chromium) we have multiple aliquots pre library request
    let(:source_well_a) { create(:tagged_well, aliquot_count: 2) }
    let(:source_well_b) { create(:tagged_well) }
    let(:target_well) { create(:empty_well) }
    let(:submission) { create(:submission) }
    let(:order) do
      create(
        :library_order,
        submission: submission,
        request_types: [library_request_type.id, multiplex_request_type.id],
        assets: [source_well_a, source_well_b]
      )
    end
    let(:multiplexed_library_tube) { create(:multiplexed_library_tube, aliquots: []) }
    let(:library_request_a) do
      create(
        :library_request,
        asset: source_well_a,
        target_asset: target_well,
        submission: submission,
        order: order,
        state: 'passed',
        request_type: library_request_type
      )
    end
    let(:library_request_b) do
      create(
        :library_request,
        asset: source_well_b,
        target_asset: target_well,
        submission: submission,
        order: order,
        state: 'passed',
        request_type: library_request_type
      )
    end

    # While source and target assets are the same, we actually have two requests
    let(:multiplex_request_a) do
      create(
        :multiplex_request,
        asset: target_well,
        target_asset: multiplexed_library_tube,
        submission: submission,
        order: order,
        request_type: multiplex_request_type
      )
    end
    let(:multiplex_request_b) do
      create(
        :multiplex_request,
        asset: target_well,
        target_asset: multiplexed_library_tube,
        submission: submission,
        order: order,
        request_type: multiplex_request_type
      )
    end

    # Order here matters
    before do
      order
      library_request_a
      library_request_b
      multiplex_request_a
      multiplex_request_b
      create(:transfer_request, asset: source_well_a, target_asset: target_well, submission: submission)
      create(:transfer_request, asset: source_well_b, target_asset: target_well, submission: submission)
    end

    it 'associated each aliquot with a different library request' do
      create(:transfer_request, asset: target_well, target_asset: multiplexed_library_tube, submission: submission)
      expect(multiplexed_library_tube.reload.aliquots.map(&:request_id)).to eq(
        [multiplex_request_a.id, multiplex_request_a.id, multiplex_request_b.id]
      )
    end
  end

  describe '#aliquots_for_transfer (indirectly via save)' do
    let(:source) { create(:tagged_well) }
    let(:destination) { create(:tube) }
    let(:transfer_request) do
      described_class.new(
        asset: source,
        target_asset: destination,
        merge_equivalent_aliquots: merge_flag,
        keep_this_aliquot_when_deduplicating: keep_flag,
        list_of_aliquot_attributes_to_consider_a_duplicate: aliquot_attributes
      )
    end

    let(:source_aliquot) { source.aliquots.first }
    let(:destination_aliquot) do
      create(
        :aliquot,
        sample: source_aliquot.sample,
        study: source_aliquot.study,
        project: source_aliquot.project,
        tag: source_aliquot.tag,
        tag2: source_aliquot.tag2
      )
    end

    let(:aliquot_attributes) { nil }
    # let(:aliquot_attributes) { %w[sample_id tag_id tag2_id] }
    let(:merge_flag) { nil }
    let(:keep_flag) { nil }

    before { destination.aliquots << destination_aliquot }

    context 'when merge_equivalent_aliquots is true' do
      let(:merge_flag) { true }

      it 'does not add the equivalent aliquot to the target' do
        expect { transfer_request.save! }.not_to(change { destination.aliquots.reload.count })
        expect(destination.aliquots.reload).to include(destination_aliquot)
        expect(destination.aliquots.reload).not_to include(source_aliquot)
      end
    end

    context 'when merge_equivalent_aliquots is false' do
      let(:merge_flag) { false }

      it 'raises a TagClash exception' do
        expect { transfer_request.save! }.to raise_error(
          Aliquot::TagClash,
          /contains aliquots which can't be transferred due to tag clash/
        )
      end
    end

    context 'when keep_this_aliquot_when_deduplicating is true' do
      let(:merge_flag) { true }
      let(:keep_flag) { true }

      it 'removes the existing aliquot and dups the candidate aliquot' do
        # Save the transfer request to trigger the logic
        expect_no_change_in_aliquot_count

        # Ensure the destination no longer includes the original destination aliquot
        expect_destination_does_not_include_original_aliquot

        # Ensure the destination includes a new aliquot
        expect_new_aliquot_in_destination
      end

      # Helper methods
      def expect_no_change_in_aliquot_count
        expect { transfer_request.save! }.not_to(change { destination.aliquots.reload.count })
      end

      def expect_destination_does_not_include_original_aliquot
        expect(destination.aliquots).not_to include(destination_aliquot)
      end

      def expect_new_aliquot_in_destination
        new_aliquot = find_new_aliquot
        validate_new_aliquot(new_aliquot)
      end

      def find_new_aliquot
        destination.aliquots.find { |aliquot| aliquot != destination_aliquot }
      end

      def validate_new_aliquot(new_aliquot)
        expect(new_aliquot).not_to eq(destination_aliquot)
        expect(new_aliquot).not_to eq(source_aliquot)
        expect(new_aliquot.equivalent?(source_aliquot)).to be true
      end
    end

    context 'when keep_this_aliquot_when_deduplicating is false' do
      let(:merge_flag) { true }
      let(:keep_flag) { false }

      it 'rejects the candidate aliquot' do
        expect { transfer_request.save! }.not_to(change { destination.aliquots.reload.map(&:id) })
        expect(destination.aliquots.reload).to include(destination_aliquot)
        expect(destination.aliquots.reload).not_to include(source_aliquot)
      end
    end
  end
end
