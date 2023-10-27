# frozen_string_literal: true

FactoryBot.define do
  factory :location_report, class: 'LocationReport' do
    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type { :type_selection }

    factory :location_report_selection do
    end

    factory :location_report_labwhere do
      report_type { :type_labwhere }
    end
  end

  factory(:location_report_form, class: 'LocationReport::LocationReportForm') do
    skip_create

    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type { :type_selection }
    barcodes_text { 'DN1S' }
  end
end
