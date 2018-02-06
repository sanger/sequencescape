# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get Aker Product', type: :request, aker: true do
  let!(:product) { create(:aker_product_with_process_module_pairings, number_of_pairs: 5) }

  before(:each) do
    get aker_product_path(product)
  end

  it 'is successful' do
    expect(response).to be_success
  end

  it 'contains the product details' do
    json = ActiveSupport::JSON.decode(response.body)['product']
    expect(json['name']).to eq(product.name)
    expect(json['description']).to eq(product.description)
  end

  it 'contains the processes' do
    json = ActiveSupport::JSON.decode(response.body)['product']['processes']
    expect(json.length).to eq(1)
    process = json.first
    expect(process['name']).to eq(product.processes.first.name)
  end

  it 'contains the process module pairings for each process' do
    json = ActiveSupport::JSON.decode(response.body)['product']['processes'].first['process_module_pairings']
    process_module_pairing = product.processes.first.process_module_pairings.first
    expect(json.length).to eq(5)
    json = json.first
    expect(json['from_step']).to eq(process_module_pairing.from_step.name)
    expect(json['to_step']).to eq(process_module_pairing.to_step.name)
  end
end
