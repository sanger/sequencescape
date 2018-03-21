# frozen_string_literal: true

FactoryGirl.define do
  factory :plate_barcode do
    sequence(:barcode) { |i| i }
    skip_create
  end

  factory :barcode_printer_type do
    sequence(:name) { |i| "Printer Type #{i}" }
  end

  factory :plate_barcode_printer_type, class: BarcodePrinterType96Plate do
    sequence(:name) { |i| "96 Well Plate #{i}" }
    printer_type_id 1
    label_template_name 'sqsc_96plate_label_template'
  end
end
