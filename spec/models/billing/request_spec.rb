# frozen_string_literal: true

require 'rails_helper'

describe Request, billing: true do
  it 'creates a billing item if the request is in the right state' do
    request = create(:sequencing_request_with_assets, request_type: create(:sequencing_request_type), billing_product: (create :billing_product))
    request.start!
    request.pass!
    expect(request.billing_items).not_to be_empty
  end

  it 'does not create a billing item if the request is not in the right state' do
    request = create(:sequencing_request_with_assets, request_type: create(:sequencing_request_type))
    request.start!
    request.pass!
    expect(request.billing_items).to be_empty

    request = create(:sequencing_request_with_assets, request_type: create(:sequencing_request_type), billing_product: (create :billing_product))
    request.start!
    request.target_asset.aliquots << create_list(:aliquot, 3)
    request.save
    expect(request.billing_items).to be_empty
  end

  it 'does not create a billing item if the request has already been billed' do
    request = create(:sequencing_request_with_assets, request_type: create(:sequencing_request_type), billing_product: (create :billing_product))
    request.start!
    request.pass!
    number_of_billing_items = request.billing_items.count
    request.save
    request.reload
    expect(request.billing_items.count).to eq(number_of_billing_items)
  end

  it 'does not create a billing item if the request does not adhere to billing item validation' do
    request = create(:sequencing_request_with_assets, request_type: create(:sequencing_request_type, key: 'illumina_c_miseq_sequencing'), billing_product: (create :billing_product))
    request.start!
    request.target_asset.aliquots = []
    request.pass!
    expect(request.billing_items).to be_empty
  end
end
