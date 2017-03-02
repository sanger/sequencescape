require 'rails_helper'

describe Billing::BillingFile do
  before(:each) do
    @request1 = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'HiSeq 2500 Paired end sequencing', billable: true)
    @request2 = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'MiSeq sequencing', billable: true)
    @request3 = create :request_with_sequencing_request_type, request_type: (create :sequencing_request_type, name: 'MiSeq sequencing')
    event1 = create :passed_request_event
    event2 = create :passed_request_event
    @request1.request_events << event1
    @request2.request_events << event2
    @file = Billing::BillingFile.new(file_name: 'test_file', month: '2')
  end

  it 'should have file_name, the right requests, generate the right data' do
    Billing::BillingFile.any_instance.stub(:period).and_return(Date.new(2012, 8, 1)..Date.new(2012, 8, -1))
    expect(@file.file_name).to eq 'test_file'
    expect(@file.seq_requests.count). to eq 2
    data = "STD                      BI                       LM                       GLGR                       3730                                              no_project               HISEQ2500PAIREDENDSEQ76                                                    ILL                                               XX                                                GBP                                           0                   0           100                                                         HiSeq 2500 Paired end sequencing                                                                                                                                                                                                                               2012082920120829\nSTD                      BI                       LM                       GLGR                       3730                                              no_project               MISEQSEQ76                                                                 ILL                                               XX                                                GBP                                           0                   0           100                                                         MiSeq sequencing                                                                                                                                                                                                                                               2012082920120829\n" # rubocop:disable Metrics/LineLength
    expect(@file.data).to eq data
  end
end
