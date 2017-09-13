require 'rails_helper'

describe 'Billing::Factories', billing: true do
  let!(:request) { create :sequencing_request_with_assets }

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
    expect(billing_item.fin_product_code).to eq(factory.fin_product_code)
    expect(billing_item.fin_product_description).to eq(factory.fin_product_description)
    expect(billing_item.request_passed_date).to eq(factory.passed_date)
  end

  describe Billing::Factory::LibraryCreation do
    subject do
      request.start!
      request.pass!
      request.update_attributes(initial_project: create(:project))
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
      request.target_asset.aliquots << create_list(:aliquot, 3)
      factory = Billing::Factory::Sequencing.new(request: request)
      factory.create!
      expect(Billing::Item.count).to eq(2)
      expect(Billing::Item.first.units).to eq '25'
      expect(Billing::Item.last.units).to eq '75'
    end
  end

  describe 'build' do
    it 'builds a sequencing factory for the relevant request types' do
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_miseq_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_hiseq_2500_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_b_hiseq_2500_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_b_hiseq_2500_single_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_hiseq_2500_single_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_b_miseq_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_b_hiseq_v4_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_hiseq_v4_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_b_hiseq_x_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_hiseq_v4_single_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'bespoke_hiseq_x_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_htp_hiseq_4000_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
      expect(Billing::Factory.build(create(:request, request_type: RequestType.find_by(key: 'illumina_c_hiseq_4000_paired_end_sequencing')))).to be_instance_of(Billing::Factory::Sequencing)
    end

    it 'builds a library creation factory for the relevant request types' do
      expect(Billing::Factory.build(create(:request, request_type: create(:request_type, key: 'limber_wgs')))).to be_instance_of(Billing::Factory::LibraryCreation)
      expect(Billing::Factory.build(create(:request, request_type: create(:request_type, key: 'limber_isc')))).to be_instance_of(Billing::Factory::LibraryCreation)
      expect(Billing::Factory.build(create(:request, request_type: create(:request_type, key: 'limber_pcr_free')))).to be_instance_of(Billing::Factory::LibraryCreation)
      expect(Billing::Factory.build(create(:request, request_type: create(:request_type, key: 'limber_lcmb')))).to be_instance_of(Billing::Factory::LibraryCreation)
    end
  end
end
