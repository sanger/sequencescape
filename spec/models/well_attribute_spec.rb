# frozen_string_literal: true

require 'rails_helper'

describe WellAttribute do
  let(:well_attribute) { create(:well_attribute) }
  let(:well) { create(:well, well_attribute:) }
  let!(:warehouse_message) { Messenger.create!(target: well, template: 'WellStockResourceIO', root: 'stock_resource') }

  it 'does not let current_volume to get negative' do
    well_attribute.current_volume = -2
    well_attribute.save
    expect(well_attribute.current_volume).to eq 0.0
    expect(described_class.last.current_volume).to eq 0.0
    well_attribute.update!(current_volume: 1)
    expect(well_attribute.current_volume).to eq 1.0
    expect(described_class.last.current_volume).to eq 1.0
  end

  it 'triggers warehouse message on well attribute update', :warren do
    current_message_count = Warren.handler.messages.count
    expect { well_attribute.update(concentration: 200) }.to change(Warren.handler.messages, :count).from(
      current_message_count
    )
    expect(Warren.handler.messages_matching("queue_broadcast.messenger.#{warehouse_message.id}")).to be 2
  end
end
