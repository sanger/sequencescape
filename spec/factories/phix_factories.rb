# frozen_string_literal: true

FactoryBot.define do
  factory :phi_x_stock, class: 'PhiX::Stock' do
    to_create(&:save)

    name { 'PhiX Stock' }
    tags { 'Dual' }
    concentration { '9.2' }
    number { '1' }
    study_id { create(:study).id }
  end

  factory :phi_x_spiked_buffer, class: 'PhiX::SpikedBuffer' do
    to_create(&:save)

    name { 'PhiX Spiked Buffer' }
    concentration { '9.2' }
    parent_barcode { parent.machine_barcode }
    parent { create(:phi_x_stock_tube) }
    volume { '10.0' }
    number { '1' }
  end
end
