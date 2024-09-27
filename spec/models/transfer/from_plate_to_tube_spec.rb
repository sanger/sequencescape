# frozen_string_literal: true

require 'rails_helper'

describe Transfer::FromPlateToTube do
  let(:transfer_without_transfers) { create(:transfer_from_plate_to_tube) }
  let(:transfer_with_transfers) { create(:transfer_from_plate_to_tube_with_transfers) }

  it 'transfers all wells by default' do
    expect(transfer_without_transfers.transfers).to eq(%w[A1 B1 C1])
  end

  it 'transfers only the specified transfers' do
    expect(transfer_with_transfers.transfers).to eq(%w[A1 B1])
  end

  it 'does not override tranfers upon save' do
    transfer_without_transfers.transfers = %w[A1]
    transfer_without_transfers.save
    transfer_without_transfers.reload
    expect(transfer_without_transfers.transfers).to eq(%w[A1])
  end
end
