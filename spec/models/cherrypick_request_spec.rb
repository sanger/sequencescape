# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe CherrypickRequest do
  let(:source_asset) { create :tagged_well }
  let(:target_asset) { create :empty_well }

  before { create :cherrypick_request, asset: source_asset, target_asset: }

  it 'transfers the contents of the source asset to the target asset' do
    expect(target_asset.aliquots.length).to eq(source_asset.aliquots.length)
  end

  it 'creates a transfer request between the source and target assets' do
    # This behaviour is required for the Generic Lims pipelines due to limitations
    # in the state machine.
    expect(source_asset.transfer_requests_as_source.count).to eq(1)
    expect(source_asset.transfer_requests_as_source.first.target_asset).to eq(target_asset)
  end
end
