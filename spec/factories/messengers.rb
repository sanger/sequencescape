# frozen_string_literal: true

FactoryBot.define do
  factory :messenger_creator do
    root { 'a_plate' }
    template { 'FluidigmPlateIo' }
    purpose { |purpose| purpose.association(:plate_purpose) }
  end

  factory :messenger do
    root { 'barcode' }
    target factory: %i[barcode]
    template { 'BarcodeIO' }

    factory :flowcell_messenger do
      root { 'flowcell' }
      target factory: %i[sequencing_batch]
      template { 'FlowcellIo' }
    end
  end
end
