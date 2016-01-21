#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
FactoryGirl.define do
  factory :qc_report do |qc|
    qc.study {|study| study.association(:study) }
    qc.product_criteria {|pc| pc.association(:product_criteria) }
    qc.exclude_existing false
  end

  factory :qc_metric do |qc|
    qc.qc_report        {|qcr| qcr.association(:qc_report) }
    qc.asset            {|a|  a.association(:well) }
  end
end
