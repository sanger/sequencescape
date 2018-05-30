# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2018 Genome Research Ltd.

FactoryBot.define do
  factory :location_report, class: LocationReport do
    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type :type_selection

    factory :location_report_selection do
    end

    factory :location_report_labwhere do
      report_type :type_labwhere
    end
  end

  factory(:location_report_form, class: LocationReport::LocationReportForm) do
    skip_create

    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type :type_selection
    barcodes_text 'DN1S'
  end
end
