# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TransferRequestCollection, type: :model, transfer_request_collection: true do
  let(:user) { create :user }
  let(:asset) { create :tagged_well }
  let(:target_asset) { create :empty_library_tube }

  subject { described_class.new(creation_attributes) }

  context 'with a single transfer' do
    let(:creation_attributes) do
      {
        user: user,
        transfer_requests_attributes: [
          { asset: asset, target_asset: target_asset }
        ]
      }
    end

    describe '#save' do
      let(:transfer_request) { subject.transfer_requests.first }

      before do
        expect(subject.save).to be true
      end

      it 'creates a transfer request' do
        expect(subject.transfer_requests.count).to eq(1)
      end

      it 'sets the expected asset' do
        expect(transfer_request.asset).to eq(asset)
      end

      it 'sets the expected target_asset' do
        expect(transfer_request.target_asset).to eq(target_asset)
      end
    end
  end
end
