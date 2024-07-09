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

  describe '::for_user' do
    subject(:batch_for_user) { described_class.for_user(query) }

    let(:user) { create :user }
    let!(:owned_batch) { create :batch, user: user }
    let!(:assigned_batch) { create :batch, assignee: user }
    let!(:other_batch) { create :batch }

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

  # This test is a flaky test because it leaks state between tests.
  # It is not clear what the state is that is leaking.
  # This can be removed with proper classes and tests in Y24-040, as this is a test for a feature that is not yet used.
  describe "::add_dynamic_validations" do

    let(:pipeline) { create :pipeline, validator_class_name: 'NovaSeq6000Validator' }
    let(:batch) { described_class.new pipeline: pipeline}

    before do
      stub_const('NovaSeq6000Validator', Class.new(CustomValidatorBase) do
        def validate(record)
          record.errors.add :base, 'NovaSeq6000Validator failed'
        end
      end)
    end

    context 'when added, includes the dynamic validations' do
      xit 'adds dynamic validations' do
        expect(batch.valid?).to be false
        expect(batch.errors[:base]).to include('NovaSeq6000Validator failed')
      end
    end
  end
end
