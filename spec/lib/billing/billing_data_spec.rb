require 'rails_helper'

describe Billing::BillingData do

  before(:each) do
   request = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'Request Type 1')
   event = create :request_event
   request.request_events << event
   @data = Billing::BillingData.new(request: request)
  end

  it 'should have a request' do
    expect(@data.request).to be_an_instance_of Request
  end

  it 'should create a correct line for a file' do
    line = "STD                      BI                       LMGLGR                       3730                                              project_cost_code        Request Type 176         ILL                      XX                       GBP                                         0                   0units               Request Type 1                                                                                                                                                                                                                                                 2012082920120829\n"
    expect(@data.line('project_cost_code', 'units')).to eq line
  end

end