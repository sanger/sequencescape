# frozen_string_literal: true

# TODO: This is not a valid factory. It fails to build because of the lack of barcodes

FactoryBot.define do
  factory :location_report, class: 'LocationReport' do


    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type { :type_selection }
    # barcodes { create_list(:plate, 3).collect { |plate| plate.barcodes.first.barcode } }
    factory :location_report_selection do
    end

    factory :location_report_labwhere do
      report_type { :type_labwhere }
      # location_barcode { 'DN1S' }
    end
  end

  factory(:location_report_form, class: 'LocationReport::LocationReportForm') do
    skip_create

    user
    sequence(:name) { |n| "Location Report #{n}" }
    report_type { :type_selection }
    barcodes_text { 'DN1S' }
    # barcodes { create_list(:plate, 3).collect { |plate| plate.barcodes.first.barcode } }

  end
end
