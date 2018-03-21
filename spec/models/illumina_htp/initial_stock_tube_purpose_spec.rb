require 'rails_helper'

describe IlluminaHtp::InitialStockTubePurpose do
  let(:tube_purpose) { create :illumina_htp_initial_stock_tube_purpose }
  let(:tube) { create :stock_multiplexed_library_tube, purpose: tube_purpose }

  describe '#sibling_tubes' do
    subject { tube_purpose.sibling_tubes(tube) }

    let(:current_submission) { create :submission }

    let(:parent_well) do
      well = create :well
      well.stock_wells << well
      well
    end

    let(:sibling_tube) { create :stock_multiplexed_library_tube, purpose: tube_purpose }
    let(:sibling_tube_hash) { { name: sibling_tube.name, uuid: sibling_tube.uuid, ean13_barcode: sibling_tube.ean13_barcode, state: sibling_state } }
    let(:target_tube) { create :multiplexed_library_tube }
    let(:sibling_state) { 'pending' }

    before do
      create :transfer_request, asset: parent_well, target_asset: tube, submission: current_submission
      create :transfer_request, asset: parents_sibling_well, target_asset: sibling_tube, submission: sibling_submission, state: sibling_state
      lr = create :library_request, asset: parent_well, target_asset: target_tube, submission: current_submission
      create :library_request, asset: parents_sibling_well, target_asset: target_tube, submission: sibling_submission, request_type: lr.request_type
    end

    context 'with siblings' do
      let(:sibling_submission) { current_submission }
      let(:parents_sibling_well) { create :well }
      it { is_expected.to be_a Array }
      it { is_expected.to include(sibling_tube_hash) }
    end

    context 'with wells which are also siblings' do
      let(:sibling_submission) { current_submission }
      let(:sibling_tube) { create(:well) }
      let(:parents_sibling_well) { create :well }

      it { is_expected.to be_a Array }
      it { is_expected.not_to include(sibling_tube) }
    end

    context 'with unrelated requests out the same well' do
      let(:sibling_submission) { create :submission }
      let(:parents_sibling_well) { parent_well }
      it { is_expected.to be_a Array }
      it { is_expected.not_to include(sibling_tube_hash) }
    end

    context 'with related requests out the same well' do
      context 'which are cancelled' do
        let(:sibling_submission) { current_submission }
        let(:parents_sibling_well) { parent_well }
        let(:sibling_state) { 'cancelled' }
        it { is_expected.to be_a Array }
        it { is_expected.not_to include(sibling_tube_hash) }
      end

      context 'which are pending' do
        # Currently these are found as siblings. This is usually a result
        # of users creating tubes multiple times. We probably COULD ignore
        # these siblings. But I'm focussing on ignoring cancelled tubes first.
      end
    end
  end
end
