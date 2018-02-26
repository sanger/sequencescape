# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

FactoryGirl.define do
  factory :location_report, class: LocationReport do
    user

    factory :location_report_selection do
      report_type   'selection'
    end

    factory :location_report_barcodes do
      report_type   'barcodes'
    end
  end
end
