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
      create :transfer_request, asset: source, target_asset: destination, submission: library_request.submission
    end

    let(:library_request) do
      create :library_request,
             asset: source,
             initial_study: example_study,
             initial_project: example_project,
             state: library_state
    end

    context 'with volume' do
      subject do
        create :transfer_request,
               asset: source,
               target_asset: destination,
               submission: library_request.submission,
               volume: 4.5
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
        create :gbs_request,
               state: 'pending',
               asset: source,
               initial_study: example_study,
               initial_project: example_project
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
    subject { create :transfer_request, asset: source, target_asset: destination, outer_request: library_request }

    before do
      library_request
      dummy_library_request
    end

    let(:library_request) do
      create :library_request,
             asset: source,
             initial_study: example_study,
             initial_project: example_project,
             state: library_state
    end

    let(:dummy_library_request) do
      create :library_request,
             asset: source,
             initial_study: example_study,
             initial_project: example_project,
             state: library_state,
             submission: library_request.submission
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
        let(:source) { create :well_with_sample_and_without_plate, stock_wells: create_list(:well, 2) }

        it 'sets the stock wells' do
          expect(destination.stock_wells).to eq(source.stock_wells)
        end
      end

      context 'when the source is a stock well' do
        let(:source) { create :well_with_sample_and_without_plate, plate: create(:stock_plate) }

        it 'sets the stock wells' do
          expect(destination.stock_wells).to eq([source])
        end
      end
    end

    # TODO: Feature Cardinal - Uncomment following:
    # BEGIN FEATURE CARDINAL
    # context 'when building using tag_depth' do
    #   context 'when building several transfer requests' do
    #     let(:transfer_request) do
    #       described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 1 })
    #     end

    #     context 'with the same tag depth' do
    #       let(:transfer_request2) do
    #         described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 1 })
    #       end

    #       it 'cannot create several requests into the same destination' do
    #         expect { [transfer_request, transfer_request2] }.to raise_error Aliquot::TagClash
    #       end
    #     end

    #     context 'with the different tag depth' do
    #       let(:transfer_request2) do
    #         described_class.create!(asset: source, target_asset: destination, aliquot_attributes: { tag_depth: 2 })
    #       end

    #       it 'can create several requests into the same destination, allowing tag clash' do
    #         expect { [transfer_request, transfer_request2] }.not_to raise_error
    #       end
    #     end
    #   end
    # end
    # END FEATURE CARDINAL

    context 'when the destination has equivalent aliquots' do
      let(:equivalent_aliquot) { source.aliquots.first.dup }
      let(:destination) { create :well, aliquots: [equivalent_aliquot] }
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
          expect { transfer_request.save }.to raise_error(Aliquot::TagClash)
        end
      end
    end

    it 'does not permit transfers to the same asset' do
      asset = create(:sample_tube)
      expect { described_class.create!(asset: asset, target_asset: asset) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'with a tag clash' do
      let!(:tag) { create :tag }
      let!(:tag2) { create :tag }
      let!(:aliquot_1) { create :aliquot, tag: tag, tag2: tag2 }
      let!(:aliquot_2) { create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well) }
      let!(:target_asset) { create :well, aliquots: [aliquot_1] }

      it 'raises an exception' do
        expect do
          described_class.create!(asset: aliquot_2.receptacle.reload, target_asset: target_asset)
        end.to raise_error(Aliquot::TagClash)
      end
    end
  end

  describe 'state_machine' do
    subject { build :transfer_request }

    {
      start: {
        pending: :started
      },
      pass: {
        pending: :passed,
        started: :passed,
        failed: :passed,
        processed_2: :passed
      },
      process_1: {
        pending: :processed_1
      },
      process_2: {
        processed_1: :processed_2
      },
      qc: {
        passed: :qc_complete
      },
      fail: {
        pending: :failed,
        started: :failed,
        processed_1: :failed,
        processed_2: :failed,
        passed: :failed
      },
      cancel: {
        started: :cancelled,
        processed_1: :cancelled,
        processed_2: :cancelled,
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
          tf = build :transfer_request, state: state
          expect(tf).not_to allow_event(event)
        end
      end
    end
  end

  context 'outer request' do
    let(:last_well) { create :well_with_sample_and_without_plate }
    let(:example_study) { create :study }
    let(:example_project) { create :project }

    let(:library_request) { create :library_request, asset: stock_asset, submission: create(:submission) }

    before do
      # A decoy library request, this is part of a different submission and
      # should be ignored
      create :library_request, asset: stock_asset, submission: create(:submission)
      last_well.stock_wells << stock_asset
    end

    let(:transfer_request) { create :transfer_request, asset: source_asset, submission: library_request.submission }

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

        before do
          create :transfer_request, asset: last_well, target_asset: source_asset, submission: library_request.submission
        end

        it { is_expected.to eq library_request }
      end
    end
  end

  context 'transfer downstream of pooling (such as in ISC)' do
    let(:library_request_type) { create :library_request_type }
    let(:multiplex_request_type) { create :multiplex_request_type }

    # In some cases (such as chromium) we have multiple aliquots pre library request
    let(:source_well_a) { create :tagged_well, aliquot_count: 2 }
    let(:source_well_b) { create :tagged_well }
    let(:target_well) { create :empty_well }
    let(:submission) { create :submission }
    let(:order) do
      create :library_order,
             submission: submission,
             request_types: [library_request_type.id, multiplex_request_type.id],
             assets: [source_well_a, source_well_b]
    end
    let(:multiplexed_library_tube) { create :multiplexed_library_tube, aliquots: [] }
    let(:library_request_a) do
      create :library_request,
             asset: source_well_a,
             target_asset: target_well,
             submission: submission,
             order: order,
             state: 'passed',
             request_type: library_request_type
    end
    let(:library_request_b) do
      create :library_request,
             asset: source_well_b,
             target_asset: target_well,
             submission: submission,
             order: order,
             state: 'passed',
             request_type: library_request_type
    end

    # While source and target assets are the same, we actually have two requests
    let(:multiplex_request_a) do
      create :multiplex_request,
             asset: target_well,
             target_asset: multiplexed_library_tube,
             submission: submission,
             order: order,
             request_type: multiplex_request_type
    end
    let(:multiplex_request_b) do
      create :multiplex_request,
             asset: target_well,
             target_asset: multiplexed_library_tube,
             submission: submission,
             order: order,
             request_type: multiplex_request_type
    end

    # Order here matters
    before do
      order
      library_request_a
      library_request_b
      multiplex_request_a
      multiplex_request_b
      create :transfer_request, asset: source_well_a, target_asset: target_well, submission: submission
      create :transfer_request, asset: source_well_b, target_asset: target_well, submission: submission
    end

    it 'associated each aliquot with a different library request' do
      create :transfer_request, asset: target_well, target_asset: multiplexed_library_tube, submission: submission
      expect(multiplexed_library_tube.reload.aliquots.map(&:request_id)).to eq(
        [multiplex_request_a.id, multiplex_request_a.id, multiplex_request_b.id]
      )
    end
  end
end
