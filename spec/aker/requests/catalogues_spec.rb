# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Get Aker Catalogue', type: :request, aker: true do
  describe 'index' do
    let!(:catalogues) { create_list(:aker_catalogue, 5) }

    before(:each) do
      get aker_catalogues_path
    end

    it 'is successful' do
      expect(response).to be_success
    end

    it 'contains the product details' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json.length).to eq(5)
    end
  end

  describe 'show' do
    let!(:catalogue) { create(:aker_catalogue_with_product_and_process_module_pairings, number_of_pairs: 5) }

    before(:each) do
      get aker_catalogue_path(catalogue)
    end

    it 'is successful' do
      expect(response).to be_success
    end

    it 'contains the catalogue details' do
      json = ActiveSupport::JSON.decode(response.body)['catalogue']
      expect(json['pipeline']).to eq(catalogue.pipeline)
      expect(json['url']).to eq(catalogue.url)
      expect(json['lims_id']).to eq(catalogue.lims_id)
    end

    it 'contains the products' do
      json = ActiveSupport::JSON.decode(response.body)['catalogue']['products']
      expect(json.length).to eq(1)
      product = catalogue.products.first
      json = json.first
      expect(json['name']).to eq(product.name)
      expect(json['description']).to eq(product.description)
      expect(json['product_version']).to eq(product.product_version)
      expect(json['availability']).to eq(product.availability)
      expect(json['requested_biomaterial_type']).to eq(product.requested_biomaterial_type)
      expect(json['product_class']).to eq(product.product_class)
    end

    it 'contains the processes' do
      json = ActiveSupport::JSON.decode(response.body)['catalogue']['products'].first['processes']
      expect(json.length).to eq(1)
      process = json.first
      expect(process['name']).to eq(catalogue.products.first.processes.first.name)
      expect(process['TAT']).to eq(catalogue.products.first.processes.first.tat)
    end

    it 'contains the process module pairings for each process' do
      json = ActiveSupport::JSON.decode(response.body)['catalogue']['products'].first['processes'].first['process_module_pairings']
      process_module_pairing = catalogue.products.first.processes.first.process_module_pairings.first
      expect(json.length).to eq(5)
      json = json.first
      expect(json['from_step']).to eq(process_module_pairing.from_step.name)
      expect(json['to_step']).to eq(process_module_pairing.to_step.name)
      expect(json['default_path']).to eq(process_module_pairing.default_path)
    end
  end
end
