# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

FactoryGirl.define do
  factory :location_report, class: LocationReport do
    user
    sequence(:name) { |n| "Tag Group #{n}" }
    report_type :type_barcodes
    barcodes_text 'DN1S'

    factory :location_report_barcodes do
    end

    factory :location_report_selection do
      report_type :type_selection

      before(:create) { create(:plate_with_wells_for_specified_studies, created_at: '2018-01-02 00:00:00') }

      start_date  '2018-01-01 00:00:00'
      end_date    '2018-01-03 00:00:00'
    end
  end
end
