# frozen_string_literal: true

# rubocop:disable Style/SymbolArray

namespace :qc_assay do
  barcodes_values = [
    ['DN581639U', 100], ['DN575795T', 50], ['DN575798W', 50], ['DN575799A', 50],
    ['DN575800W', 50], ['DN575801A', 50], ['DN575802B', 50], ['DN575803C', 50]
  ]

  key = 'volume'
  assay_type = 'RT_666755_reset'

  desc 'Create forged QcResults'
  task create: [:environment] do
    ActiveRecord::Base.transaction do
      qc_assay = QcAssay.create!
      barcodes_values.each do |barcode, value|
        plate = Plate.includes(:wells).with_barcode(barcode).first
        plate.wells.each do |w|
          qc_assay.qc_results.create!(
            asset: w,
            key: key,
            value: value.to_f,
            assay_type: assay_type,
            units: 'ul',
            assay_version: 'v0.0'
          )
        end
      end
    end
  end

  desc 'Check current volumes'
  task check: [:environment] do
    ActiveRecord::Base.transaction do
      barcodes_values.each do |barcode, volume|
        plate = Plate.includes(wells: [:well_attribute, :map]).with_barcode(barcode).first
        plate.wells.each do |w|
          act_vol = w.get_current_volume
          check = volume == act_vol
          puts "#{barcode}:#{w.map_description} : #{volume} = #{act_vol} #{check ? '✔' : '✗' * 20}"
          raise 'Unexpected volume' unless check
        end
      end
    end
  end
end

# rubocop:enable Style/SymbolArray
