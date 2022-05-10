# frozen_string_literal: true

FactoryBot.define do
  factory :plate_barcode, class: 'Barcode' do
    format { 'sequencescape22' }
    barcode { "#{configatron.plate_barcode_prefix}-#{generate(:barcode_number)}" }
    asset { build(:labware) }
  end

  factory :child_plate_barcode, class: 'Barcode' do
    transient do
      sequence(:child_num) { |i| i }
      parent_barcode { "#{configatron.plate_barcode_prefix}-#{generate(:barcode_number)}" }
    end
    format { 'sequencescape22' }
    barcode { "#{parent_barcode}-#{child_num}" }
    asset { build(:labware) }
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
