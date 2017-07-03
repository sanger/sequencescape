require 'rails_helper'

RSpec.describe Aker::WorkOrder, type: :model, aker: true do
  it 'is not valid without an Aker ID' do
    expect(build(:work_order, aker_id: nil)).to_not be_valid
  end

  it '#to_json should include id and aker_id only' do
    work_order = create(:work_order)
    expect(work_order.as_json).to eq('work_order': { 'id': work_order.id, 'aker_id': work_order.aker_id })
  end
end
