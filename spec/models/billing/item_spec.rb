# frozen_string_literal: true

require 'rails_helper'

describe Billing::Item, billing: true do
  let!(:fields_attributes) { YAML.load_file(Rails.root.join('spec/data/billing/fields.yml')).with_indifferent_access }
  let(:fields_list) { Billing::FieldsList.new(fields_attributes) }
  let!(:billing_item) { create :billing_item }

  it 'has required attributes' do
    expect(described_class.count).to eq 1
    expect(billing_item.request.class).to eq Request
    expect(billing_item.project_cost_code).to eq 'cost_code'
    expect(billing_item.units).to eq '30'
    expect(billing_item.billing_product_code).to eq 'L1000'
    expect(billing_item.billing_product_description).to eq 'Some description'
    expect(billing_item.request_passed_date).to eq '20170727'
    expect(billing_item.reported_at).to eq nil
  end

  it 'can be converted to a right string' do
    request = create :sequencing_request
    item_attributes = { request: request,
                        project_cost_code: 'cost_code',
                        units: '30',
                        billing_product_code: 'L1000',
                        billing_product_name: 'name',
                        billing_product_description: 'Some description',
                        request_passed_date: '20170727' }
    billing_item = create :billing_item, item_attributes
    entry = "STD                      BI                       LM                       GLGR                       3730                     0223                     cost_code                L1000                                                                      ILL                                               XX                                                GBP                                           0                   0           30                                                          Some description                                                                                                                                                                                                                                               2017072720170727\n" #rubocop:disable all
    expect(billing_item.to_s(fields_list)).to eq entry
  end

  it 'can be converted to a right string if product code initially was not assigned' do
    request = create :sequencing_request
    item_attributes = { request: request,
                        project_cost_code: 'cost_code',
                        units: '30',
                        billing_product_code: '',
                        billing_product_name: 'name',
                        billing_product_description: 'Some description',
                        request_passed_date: '20170727' }
    billing_item = create :billing_item, item_attributes
    allow(Billing::AgressoProduct).to receive(:billing_product_code).and_return('L1000')
    entry = "STD                      BI                       LM                       GLGR                       3730                     0223                     cost_code                L1000                                                                      ILL                                               XX                                                GBP                                           0                   0           30                                                          Some description                                                                                                                                                                                                                                               2017072720170727\n" #rubocop:disable all
    expect(billing_item.to_s(fields_list)).to eq entry
  end
end
