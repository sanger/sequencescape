# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

describe Billing::Report, billing: true do
  before do
    Billing.configure do |config|
      config.fields = config.load_file(File.join('spec', 'data', 'billing'), 'fields')
    end
    Timecop.freeze(Time.zone.local(2017, 4, 7))
  end

  before do
    @request1 = create :sequencing_request_with_assets, billing_product: (create :billing_product, name: 'test_product_1')
    @request1.start!
    @request1.pass!
    @request2 = create :sequencing_request_with_assets, billing_product: (create :billing_product, name: 'test_product_2')
    @request2.start!
    @request2.pass!
    fields = Billing.configuration.fields
    @report = described_class.new(file_name: 'test_file', start_date: '06/04/2017', end_date: '08/04/2017', fields: fields)
  end

  after do
    Timecop.return
  end

  it 'is not valid without fields, start and end dates' do
    report = described_class.new
    expect(report.valid?).to be false
    expect(report.errors.full_messages.count).to eq 3
  end

  it 'finds the right billing items, generate the right data' do
    expect(@report.valid?).to be true
    expect(@report.billing_items.count).to eq 2
    data = "STD                      BI                       LM                       GLGR                       3730                     0223                     Some Cost Code                                                                                      ILL                                               XX                                                GBP                                           0                   0           100                                                         test_product_1                                                                                                                                                                                                                                                 2017040720170407\nSTD                      BI                       LM                       GLGR                       3730                     0223                     Some Cost Code                                                                                      ILL                                               XX                                                GBP                                           0                   0           100                                                         test_product_2                                                                                                                                                                                                                                                 2017040720170407\n" # rubocop:disable Layout/LineLength
    allow(Billing::AgressoProduct).to receive(:billing_product_code).and_return('')
    expect(@report.data).to eq data
  end
end
