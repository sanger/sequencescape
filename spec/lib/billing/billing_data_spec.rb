require 'rails_helper'

describe Billing::BillingData do
  before(:each) do
   @request = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'HiSeq 2500 Paired end sequencing')
   event = create :passed_request_event
   @request.request_events << event
   @data = Billing::BillingData.new(request: @request)
  end

  it 'should have a request' do
    expect(@data.request).to be_an_instance_of Request
  end

  it 'should produce the right product name' do
    expect(@data.dim_3).to eq 'HISEQ2500PAIREDENDSEQ76'
  end

  it 'should correctly devide units by projects' do
    aliquot1 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    aliquot2 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    expect(@data.units_by_project_cost_code).to eq('no_project' => 33, 'Some Cost Code' => 66)
  end

  it 'should create a correct line for a file' do
    line = "STD                      BI                       LM                       GLGR                       3730                                              project_cost_code        HISEQ2500PAIREDENDSEQ76                                                    ILL                                               XX                                                GBP                                           0                   0           units                                                       HiSeq 2500 Paired end sequencing                                                                                                                                                                                                                               2012082920120829\n" # rubocop:disable Metrics/LineLength
    expect(@data.line('project_cost_code', 'units')).to eq line
  end

  it 'should create correct lines for a file' do
    aliquot1 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    aliquot2 = create(:aliquot, project: (create :project), receptacle: (@request.asset))
    lines = "STD                      BI                       LM                       GLGR                       3730                                              no_project               HISEQ2500PAIREDENDSEQ76                                                    ILL                                               XX                                                GBP                                           0                   0           33                                                          HiSeq 2500 Paired end sequencing                                                                                                                                                                                                                               2012082920120829\nSTD                      BI                       LM                       GLGR                       3730                                              Some Cost Code           HISEQ2500PAIREDENDSEQ76                                                    ILL                                               XX                                                GBP                                           0                   0           66                                                          HiSeq 2500 Paired end sequencing                                                                                                                                                                                                                               2012082920120829\n" # rubocop:disable Metrics/LineLength
    expect(@data.lines).to eq lines
  end
end
