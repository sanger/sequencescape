require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe TransferRequest do
  let(:last_well) { create :well_with_sample_and_without_plate }
  let(:example_study) { create :study }
  let(:example_project) { create :project }

  let(:library_request) do
    create :library_request,
           asset: stock_asset
  end

  before do
    # A decoy library request, this is part of a different submission and
    # should be ignored
    create :library_request, asset: stock_asset
    last_well.stock_wells << stock_asset
  end

  let(:transfer_request) do
    create :transfer_request, asset: source_asset, submission: library_request.submission
  end

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
      before { create :transfer_request, asset: last_well, target_asset: source_asset }
      it { is_expected.to eq library_request }
    end
  end
end
