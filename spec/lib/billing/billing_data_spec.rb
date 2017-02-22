require 'rails_helper'

describe Billing::BillingData do
  before(:each) do
   @request = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'Request Type 1')
   event = create :request_event
   @request.request_events << event
   @data = Billing::BillingData.new(request: @request)
  end

  it 'should have a request' do
    expect(@data.request).to be_an_instance_of Request
  end

  it 'should correctly devide units by projects' do
    aliquot1 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    aliquot2 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    expect(@data.units_by_project_cost_code).to eq('no_project' => 33, 'Some Cost Code' => 66)
  end

  it 'should create a correct line for a file' do
    line = "STD                      BI                       LMGLGR                       3730                                              project_cost_code        Request Type 176         ILL                      XX                       GBP                                         0                   0units               Request Type 1                                                                                                                                                                                                                                                 2012082920120829\n"
    expect(@data.line('project_cost_code', 'units')).to eq line
  end

  it 'should create correct lines for a file' do
    aliquot1 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    aliquot2 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    lines = "STD                      BI                       LMGLGR                       3730                                              no_project               Request Type 176         ILL                      XX                       GBP                                         0                   033                  Request Type 1                                                                                                                                                                                                                                                 2012082920120829\nSTD                      BI                       LMGLGR                       3730                                              Some Cost Code           Request Type 176         ILL                      XX                       GBP                                         0                   066                  Request Type 1                                                                                                                                                                                                                                                 2012082920120829\n"
    expect(@data.lines).to eq lines
  end
end
