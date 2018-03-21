require 'rails_helper'

RSpec.describe SequencingRequest, type: :model do
  let(:library_tube) { create :library_tube }
  let(:sequencing_request) { create(:sequencing_request, asset: library_tube) }

  describe '#ready?' do
    subject { sequencing_request.ready? }

    context 'with no upstream requests as target' do
      it { is_expected.to be true }
    end

    context 'with missing assets' do
      let(:library_tube) { nil }
      it { is_expected.to be false }
    end

    context 'with empty assets' do
      let(:library_tube) { create :empty_library_tube }
      it { is_expected.to be false }
    end

    context 'with upstream requests' do
      before do
        create  :library_creation_request_for_testing_sequencing_requests,
                target_asset: library_tube,
                state: library_request_1_state
        create  :library_creation_request_for_testing_sequencing_requests,
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

    it 'should know #billing_product_identifier' do
      sequencing_request.request_metadata.update_attributes(read_length: 150)
      expect(sequencing_request.billing_product_identifier).to eq 150
    end
  end
end
