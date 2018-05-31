# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
FactoryBot.define do
  factory :qc_report do
    study
    product_criteria
    exclude_existing false
  end

  factory :qc_metric do
    qc_report
    asset            { |a| a.association(:well) }
    qc_decision      'passed'
  end
end
