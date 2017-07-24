require 'rails_helper'

describe Billing::Item do
  it 'should have required attributes' do
    request = create :sequencing_request
    billing_item = Billing::Item.create!(request: request, project_cost_code: 'project_cost_code')
    expect(Billing::Item.count).to eq 1
    expect(billing_item.request).to eq request
    expect(billing_item.project_cost_code).to eq 'project_cost_code'
    expect(billing_item.units).to eq nil
    expect(billing_item.fin_product_code).to eq nil
    expect(billing_item.fin_product_description).to eq nil
    expect(billing_item.request_passed_date).to eq nil
    expect(billing_item.reported_at).to eq nil
  end
end
