# frozen_string_literal: true

FactoryGirl.define do
  sequence(:barcode_number) { |i| i }

  factory :sanger_ean13, class: Barcode do
    transient do
      prefix 'DN'
      barcode_number
    end

    association(:asset, factory: :asset)
    format 'sanger_ean13'
    barcode { SBCF::SangerBarcode.new(prefix: prefix, number: barcode_number).human_barcode }

    factory :sanger_ean13_tube do
      transient do
        prefix 'NT'
      end
    end
  end
end
