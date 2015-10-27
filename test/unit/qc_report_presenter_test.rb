#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"
require "timecop"

class QcReportPresenterTest < ActiveSupport::TestCase

  EXPECTED_CSV = %Q{Sequencescape QC Report,1.0.0
This section is for information only and cannot be changed
Please place a Y in the proceed column for any samples you wish to proceed; use a N for samples you don't want to proceed.
Study,Example study
Product,Demo Product
Criteria Version,stock_1
Report Identifier,wtccc_demo_product_20150101000000
Generated on,"Thu, 01 Jan 2015 00:00:00 +0000"
Contents,All samples

Asset ID,Total micrograms,Comment,Qc Decision,Proceed
%s,10,X,pass,
%s,10,X,fail,
}

  context "A QcReportPresenter" do

    setup do
      @product = Factory :product, :name => 'Demo Product'
      @criteria = Factory :product_criteria, :product => @product, :version => 1
      @study  = Factory :study, :name => 'Example study'
      Timecop.freeze(DateTime.parse('01/01/2015')) do
        @report = Factory :qc_report, :study => @study, :exclude_existing => false, :created_at => DateTime.parse('01/01/2015 00:00:00'), :product_criteria => @criteria
      end
      @asset_ids = []
      2.times do |i|
        m = Factory :qc_metric, :qc_report => @report, :qc_decision => (i%2)==0, :metrics =>{:total_micrograms=>10,:comment=>'X'}
        @asset_ids << m.asset_id
      end
    end

    should 'generate an appropriate csv file' do
      csv = ""
      Presenters::QcReportPresenter.new(@report).to_csv(csv)
      assert_equal EXPECTED_CSV % @asset_ids, csv
    end

  end

end
