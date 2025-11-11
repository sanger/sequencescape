# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Batch do
  describe '::barcode_without_pick_number' do
    subject { described_class.barcode_without_pick_number(barcode_to_split) }

    let(:batch_barcode) { '550000555760' }

    context 'with a legacy barcode' do
      let(:barcode_to_split) { batch_barcode }

      it { is_expected.to eq batch_barcode }
    end

    context 'with an extended barcode' do
      let(:barcode_to_split) { "#{batch_barcode}-3" }

      it { is_expected.to eq batch_barcode }
    end
  end

  describe '::extract_pick_number' do
    subject(:extract_pick_number) { described_class.extract_pick_number(barcode_to_split) }

    let(:batch_barcode) { '550000555760' }

    # Legacy batches should return the first set
    context 'with a legacy barcode' do
      let(:barcode_to_split) { batch_barcode }

      it { is_expected.to eq 1 }
    end

    context 'with an extended barcode' do
      let(:barcode_to_split) { "#{batch_barcode}-3" }

      it { is_expected.to eq 3 }
    end

    context 'with an invalid input' do
      let(:barcode_to_split) { "#{batch_barcode}-notanumber" }

      it 'raises an error' do
        expect { extract_pick_number }.to raise_error(ArgumentError)
      end
    end
  end

  describe '::verify_tube_layout' do
    let(:user) { create(:user) }
    let!(:tube) { create(:full_library_tube) }
    let!(:target) { create(:full_library_tube) }
    let!(:pipeline) { create(:cherrypick_pipeline) }
    let!(:request) do
      create(
        :request_with_sequencing_request_type,
        asset: tube,
        target_asset: target,
        request_type: pipeline.request_types.last,
        state: 'started'
      )
    end

    let!(:batch) { create(:batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline, requests: [request]) }

    before { allow(request).to receive(:position).and_return(1) }

    context 'with machine readable barcodes' do
      it 'returns true' do
        expect(batch.verify_tube_layout([tube.machine_barcode])).to be true
      end
    end

    context 'with human readable barcodes' do
      it 'returns true' do
        expect(batch.verify_tube_layout([tube.human_barcode])).to be true
      end
    end
  end

  describe '::verify_amp_plate_layout' do
    let(:user) { create(:user) }
    let!(:tube) { create(:full_library_tube) }
    let!(:target) { create(:full_library_tube) }
    let!(:pipeline) { create(:sequencing_pipeline) }
    let!(:request) do
      create(
        :request_with_sequencing_request_type,
        asset: tube,
        target_asset: target,
        request_type: pipeline.request_types.last,
        state: 'started'
      )
    end

    let!(:batch) { create(:batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline, requests: [request]) }

    before do
      expect(LabEvent.count).to eq(0)
    end

    context 'with one plate' do
      let(:scanned_barcodes) { ["#{batch.id}_#{tube.human_barcode}"] }

      it 'returns true and makes an event' do
        expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be true
        expect(LabEvent.count).to eq(1)
        expect(batch.lab_events.last.description).to eq('AMP plate layout verified')
      end

      context 'with wrong batch id' do
        let(:scanned_barcodes) { ["wrongbatchid_#{tube.human_barcode}"] }
        let(:expected_barcode) { "#{batch.id}_#{tube.human_barcode}" }

        it 'returns false and reports errors' do
          expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be false
          expect(batch.errors[:base]).to include("The barcode at position 1 is incorrect: expected #{expected_barcode}.")
          expect(LabEvent.count).to eq(0)
        end
      end

      context 'with wrong tube barcode' do
        let(:scanned_barcodes) { ["#{batch.id}_wrongtubebarcode"] }
        let(:expected_barcode) { "#{batch.id}_#{tube.human_barcode}" }

        it 'returns false and reports errors' do
          expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be false
          expect(batch.errors[:base]).to include("The barcode at position 1 is incorrect: expected #{expected_barcode}.")
          expect(LabEvent.count).to eq(0)
        end
      end

      context 'with wrong format barcode' do
        let(:scanned_barcodes) { ['5487498572'] }
        let(:expected_barcode) { "#{batch.id}_#{tube.human_barcode}" }

        it 'returns false and reports errors' do
          expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be false
          expect(batch.errors[:base]).to include("The barcode at position 1 is incorrect: expected #{expected_barcode}.")
          expect(LabEvent.count).to eq(0)
        end
      end
    end

    context 'with two plates' do
      let!(:tube2) { create(:full_library_tube) }
      let!(:target2) { create(:full_library_tube) }
      let!(:request2) do
        create(
          :request_with_sequencing_request_type,
          asset: tube2,
          target_asset: target2,
          request_type: pipeline.request_types.last,
          state: 'started'
        )
      end

      let!(:batch) { create(:batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline, requests: [request, request2]) }

      let(:scanned_barcodes) { ["#{batch.id}_#{tube.human_barcode}", "#{batch.id}_#{tube2.human_barcode}"] }

      it 'returns true and makes an event' do
        expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be true
        expect(LabEvent.count).to eq(1)
        expect(batch.lab_events.last.description).to eq('AMP plate layout verified')
      end

      context 'with plates in wrong position' do
        let(:scanned_barcodes) { ["#{batch.id}_#{tube2.human_barcode}", "#{batch.id}_#{tube.human_barcode}"] }
        let(:expected_barcode_1) { "#{batch.id}_#{tube.human_barcode}" }
        let(:expected_barcode_2) { "#{batch.id}_#{tube2.human_barcode}" }

        it 'returns false and reports errors' do
          expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be false
          expect(batch.errors[:base]).to include("The barcode at position 1 is incorrect: expected #{expected_barcode_1}.")
          expect(batch.errors[:base]).to include("The barcode at position 2 is incorrect: expected #{expected_barcode_2}.")
          expect(LabEvent.count).to eq(0)
        end
      end

      context 'with one wrong barcode' do
        let(:scanned_barcodes) { ["#{batch.id}_#{tube.human_barcode}", "#{batch.id}_wrongtubebarcode"] }
        let(:expected_barcode) { "#{batch.id}_#{tube2.human_barcode}" }

        it 'returns false and reports errors' do
          expect(batch.verify_amp_plate_layout(scanned_barcodes)).to be false
          expect(batch.errors[:base]).to include("The barcode at position 2 is incorrect: expected #{expected_barcode}.")
          expect(LabEvent.count).to eq(0)
        end
      end
    end
  end

  describe '::for_user' do
    subject(:batch_for_user) { described_class.for_user(query) }

    let(:user) { create(:user) }
    let!(:owned_batch) { create(:batch, user:) }
    let!(:assigned_batch) { create(:batch, assignee: user) }
    let!(:other_batch) { create(:batch) }

    context 'with a user' do
      let(:query) { user }

      it 'returns owned and assigned batches', :aggregate_failures do
        expect(batch_for_user).to include(owned_batch)
        expect(batch_for_user).to include(assigned_batch)
        expect(batch_for_user).not_to include(other_batch)
      end
    end

    context 'with "all"' do
      let(:query) { 'all' }

      it 'returns owned and assigned batches', :aggregate_failures do
        expect(batch_for_user).to include(owned_batch)
        expect(batch_for_user).to include(assigned_batch)
        expect(batch_for_user).to include(other_batch)
      end
    end
  end

  describe '::add_dynamic_validations' do
    # Specific validator tests can be found in spec/validators
    let(:pipeline) { create(:pipeline, validator_class_name: 'TestPipelineValidator') }
    let(:batch) { described_class.new pipeline: }

    it 'fails validation when dynamic validations fail' do
      stub_const(
        'TestPipelineValidator',
        Class.new(ActiveModel::Validator) do
          def validate(record)
            record.errors.add :base, 'TestPipelineValidator failed'
          end
        end
      )

      expect(batch.valid?).to be false
      expect(batch.errors[:base]).to include('TestPipelineValidator failed')
    end

    it 'passes validation when dynamic validations pass' do
      stub_const(
        'TestPipelineValidator',
        Class.new(ActiveModel::Validator) do
          def validate(_record)
            true
          end
        end
      )

      expect(batch.valid?).to be true
      expect(batch.errors[:base]).to be_empty
    end
  end

  describe '#set_position_based_on_asset_barcode' do
    let(:pipeline) { create(:pipeline) }
    let(:batch) { create(:batch, pipeline:) }

    it 'sorts requests by asset human barcode' do
      # Create assets with specific barcodes to ensure consistent ordering
      asset1 = create(:sample_tube, barcode: '111')
      asset2 = create(:sample_tube, barcode: '222')
      asset3 = create(:sample_tube, barcode: '333')

      # Create requests with assets deliberately out of barcode order
      request3 = create(:request, asset: asset3)
      request1 = create(:request, asset: asset1)
      request2 = create(:request, asset: asset2)

      # Add requests to batch (order doesn't matter here)
      batch.requests << [request3, request1, request2]

      # Set up batch_requests with positions
      batch.batch_requests.each_with_index { |br, i| br.update!(position: i + 1) }

      # Set up spy for assign_positions_to_requests!
      allow(batch).to receive(:assign_positions_to_requests!)

      # Call the method under test
      batch.set_position_based_on_asset_barcode

      # Verify the method was called with correctly ordered request IDs
      expect(batch).to have_received(:assign_positions_to_requests!).with([request1.id, request2.id, request3.id])
    end
  end

  describe '#assign_positions_to_requests!' do
    let(:pipeline) { create(:pipeline) }
    let(:batch) { create(:batch, pipeline:) }

    context 'when all requests in the batch are included in the requested order' do
      it 'updates the positions of batch requests' do
        # Create requests
        request1 = create(:request)
        request2 = create(:request)
        request3 = create(:request)

        # Add requests to batch with initial positions
        batch.batch_requests.create!(request: request1, position: 3)
        batch.batch_requests.create!(request: request2, position: 1)
        batch.batch_requests.create!(request: request3, position: 2)

        # Re-order the requests
        batch.assign_positions_to_requests!([request1.id, request2.id, request3.id])

        # Reload batch and verify new positions
        batch.reload
        expect(batch.batch_requests.find_by(request_id: request1.id).position).to eq 1
        expect(batch.batch_requests.find_by(request_id: request2.id).position).to eq 2
        expect(batch.batch_requests.find_by(request_id: request3.id).position).to eq 3
      end
    end

    context 'when some requests from the batch are missing in the requested order' do
      it 'raises an error' do
        # Create requests
        request1 = create(:request)
        request2 = create(:request)
        request3 = create(:request)

        # Add all requests to batch
        batch.requests << [request1, request2, request3]

        # Try to re-order with one request missing
        expect { batch.assign_positions_to_requests!([request1.id, request3.id]) }.to raise_error(
          StandardError,
          'Can only sort all the requests in the batch at once'
        )
      end
    end

    context 'when the requested order includes IDs not in the batch' do
      it 'raises an error' do
        # Create requests
        request1 = create(:request)
        request2 = create(:request)

        # Add only two requests to batch
        batch.requests << [request1, request2]

        # Create another request but don't add to batch
        request3 = create(:request)

        # Try to re-order including the third request
        expect { batch.assign_positions_to_requests!([request1.id, request2.id, request3.id]) }.to raise_error(
          StandardError,
          'Can only sort all the requests in the batch at once'
        )
      end
    end
  end
end
