#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
Factory.define :qc_report do |qc|
  qc.study {|study| study.association(:study) }
  qc.product_criteria {|pc| pc.association(:product_criteria) }
  qc.exclude_existing { false }
end
