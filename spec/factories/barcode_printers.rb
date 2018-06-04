# frozen_string_literal: true

FactoryBot.define do
  factory(:barcode_printer) do
    sequence(:name) { |i| "a#{i}bc" }
    association(:barcode_printer_type, factory: :plate_barcode_printer_type)
  end
end
