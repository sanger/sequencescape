require 'rails_helper'

describe 'Billing::Factories', billing: true do
  let!(:request) { create :sequencing_request_with_assets, billing_product: (create :billing_product) }

  it 'is not valid without a request' do
    factory = Billing::Factory::Base.new
    expect(factory).to_not be_valid
    expect(factory.errors).to_not be_empty
  end

  it 'is not valid unless the request has a passed date' do
    factory = Billing::Factory::Base.new(request: request)
    expect(factory).to_not be_valid
    expect(factory.errors).to_not be_empty
  end

  it 'is not valid unless the request has a billing_product' do
    request = create :sequencing_request_with_assets
    factory = Billing::Factory::Base.new(request: request)
    expect(factory).to_not be_valid
    expect(factory.errors).to_not be_empty
  end

  it 'will revert no project cost code' do
    factory = Billing::Factory::Base.new(request: request)
    expect(factory.project_cost_code).to eq(Billing::Factory::Base::NO_PROJECT_COST_CODE)
  end

  it 'can have some units' do
    factory = Billing::Factory::Base.new(request: request)
    expect(factory.units).to eq(100)
  end

  it 'can create a billing item' do
    request.start!
    request.pass!
    factory = Billing::Factory::Base.new(request: request)
    billing_item = factory.create!
    expect(billing_item.request).to eq(factory.request)
    expect(billing_item.project_cost_code).to eq(factory.project_cost_code)
    expect(billing_item.units).to eq(factory.units.to_s)
    expect(billing_item.billing_product_code).to eq(factory.billing_product_code)
    expect(billing_item.billing_product_name).to eq(factory.billing_product_name)
    expect(billing_item.billing_product_description).to eq(factory.billing_product_description)
    expect(billing_item.request_passed_date).to eq(factory.passed_date)
  end

  describe Billing::Factory::LibraryCreation do
    subject do
      request.start!
      request.pass!
      request.update(initial_project: create(:project))
      Billing::Factory::LibraryCreation.new(request: request)
    end

    it 'can have some units' do
      billing_item = subject.create!
      expect(billing_item.units).to eq('100')
    end

    it 'derives cost code from project' do
      billing_item = subject.create!
      expect(billing_item.project_cost_code).to eq(request.initial_project.project_metadata.project_cost_code)
    end
  end

  describe Billing::Factory::Sequencing do
    before(:each) do
      request.start!
      request.pass!
    end

    it 'is not valid without some aliquots' do
      request.target_asset.aliquots = []
      request.save
      factory = Billing::Factory::Sequencing.new(request: request)
      expect(factory).to_not be_valid
    end

    it 'creates some billing items' do
      Billing::Item.destroy_all
      project = build(:project)
      project.project_metadata.project_cost_code = 'another_cost_code'
      project.save
      request.target_asset.aliquots << create_list(:aliquot, 3, project: project)
      factory = Billing::Factory::Sequencing.new(request: request)
      factory.create!
      expect(Billing::Item.count).to eq(2)
      expect(Billing::Item.first.units).to eq '25'
      expect(Billing::Item.first.project_cost_code).to eq 'Some Cost Code'
      expect(Billing::Item.last.units).to eq '75'
      expect(Billing::Item.last.project_cost_code).to eq 'another_cost_code'
    end
  end

  describe 'build' do
    it 'builds a sequencing factory for the request with relevant billing_product category' do
      request = create :request, billing_product: (create :billing_product, category: 'sequencing')
      expect(Billing::Factory.build(request)).to be_instance_of(Billing::Factory::Sequencing)
    end

    it 'builds a library creation factory for the request with relevant billing_product category' do
      request = create :request, billing_product: (create :billing_product, category: 'library_creation')
      expect(Billing::Factory.build(request)).to be_instance_of(Billing::Factory::LibraryCreation)
    end
  end
end
