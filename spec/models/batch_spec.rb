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
    context 'with machine readable barcodes' do
      let(:barcodes) { %w[550000555760 550000555761] }
      let(:user) { create(:user) }
      let(:tube) { create(:full_library_tube) }
      let(:target) { create(:full_library_tube) }
      let(:pipeline) { create(:cherrypick_pipeline) }
      let(:request) do
        create(
          :request_with_sequencing_request_type,
          asset: tube,
          target_asset: target,
          request_type: pipeline.request_types.last,
          state: 'started'
        )
      end

      let(:batch) { create(:batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline, requests: [request]) }
      let(:batch_request) { create(:batch_request, request: request, batch: batch, position: 1) }

      before { allow(request).to receive(:position).and_return(1) }

      it 'returns true' do
        expect(batch.verify_tube_layout([tube.machine_barcode])).to be true
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
end
