require 'rails_helper'
require 'timecop'

describe Billing::Report do

  before do
    Timecop.freeze(Time.local(2017, 4, 7))
  end

  before(:each) do
    @request1 = create :sequencing_request_with_assets, request_type: (create :sequencing_request_type, name: 'Request Type 1')
    @request1.start!
    @request1.pass!
    @request2 = create :sequencing_request_with_assets, request_type: (create :sequencing_request_type, name: 'Request Type 2')
    @request2.start!
    @request2.pass!
    Billing::ItemsFactory.new(request: @request1).create_billing_items
    Billing::ItemsFactory.new(request: @request2).create_billing_items
    fields_attributes = YAML.load_file(Rails.root.join('spec', 'data', 'billing', 'fields.yml')).with_indifferent_access
    fields = Billing::FieldsList.new(fields_attributes)
    @report = Billing::Report.new(file_name: 'test_file', start_date: '06/04/2017', end_date: '08/04/2017', fields: fields)
  end

  it 'should have file_name, the right requests, generate the right data' do
    expect(@report.file_name).to eq 'test_file'
    billing_items = @report.find_billing_items(@report.start_date, @report.end_date)
    expect(billing_items.count). to eq 2
    data = "STD                      BI                       LM                       GLGR                       3730                                              S0755                                                                                               ILL                                               XX                                                GBP                                           0                   0           100                                                         Request Type 1                                                                                                                                                                                                                                                 2017040720170407\nSTD                      BI                       LM                       GLGR                       3730                                              S0755                                                                                               ILL                                               XX                                                GBP                                           0                   0           100                                                         Request Type 2                                                                                                                                                                                                                                                 2017040720170407\n" # rubocop:disable Metrics/LineLength
    expect(@report.data(billing_items)).to eq data
  end

  after do
    Timecop.return
  end

end