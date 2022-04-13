# frozen_string_literal: true

FactoryBot.define do
  factory :plate_barcode, class: Hash do
    skip_create
    barcode { "#{configatron.plate_barcode_prefix}-#{generate(:barcode_number)}" } 

    initialize_with { attributes }
  end

  factory :barcode_printer_type do
    sequence(:name) { |i| "Printer Type #{i}" }
  end

  factory :plate_barcode_printer_type, class: 'BarcodePrinterType96Plate' do
    sequence(:name) { |i| "96 Well Plate #{i}" }
    printer_type_id { 1 }
    type { 'BarcodePrinterType96Plate' }
    label_template_name { 'sqsc_96plate_label_template_code39' }
  end
end
