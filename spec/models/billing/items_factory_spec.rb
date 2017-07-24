require 'rails_helper'

describe Billing::ItemsFactory do
  let(:request) { create :sequencing_request_with_assets }

  it 'should not be valid without request, aliquots, request passed date' do
    empty_items_factory = Billing::ItemsFactory.new
    expect(empty_items_factory.valid?).to be false
    expect(empty_items_factory.errors.messages.count).to eq 3
    items_factory = Billing::ItemsFactory.new(request: request)
    expect(items_factory.valid?).to be false
    expect(items_factory.errors.messages.count).to eq 2
  end

  it 'if valid should create correct billing items' do
    request.start!
    request.pass!
    request.target_asset.aliquots << create_list(:aliquot, 3)
    items_factory = Billing::ItemsFactory.new(request: request)
    expect(items_factory.valid?).to be true
    items_factory.create_billing_items
    expect(Billing::Item.count).to eq 2
    expect(Billing::Item.first.units).to eq '25'
    expect(Billing::Item.last.units).to eq '75'
  end
end
