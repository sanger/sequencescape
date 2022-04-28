# frozen_string_literal: true

# Move sanger format barcodes to the new tables
class MigrateSangerBarcodesToNewTables < ActiveRecord::Migration[5.1]
  def up # rubocop:disable Metrics/AbcSize
    say 'Building prefix cache'
    @prefixes = BarcodePrefix.all.pluck(:id, :prefix).to_h
    say 'Migrating Sanger Barcodes'
    Barcode.transaction do
      Asset
        .where.not(barcode_bkp: nil)
        .in_batches
        .each_with_index do |batch, i|
          say "Fetching batch #{i}"
          barcodes = batch.pluck(:id, :barcode_bkp, :barcode_prefix_id_bkp)
          say "From #{barcodes.first.first} to #{barcodes.last.first}"
          say 'Building hashes'
          barcodes_hash =
            barcodes.map do |asset_id, number, prefix_id|
              {
                asset_id: asset_id,
                barcode: SBCF::SangerBarcode.new(number: number, prefix: @prefixes[prefix_id]).human_barcode,
                format: 0
              }
            end
          say 'Importing'
          Barcode.import(barcodes_hash)
          say 'Imported'
        end
    end
    say 'Finished migrating Sanger Barcodes'
  end

  def down
    Barcode.where(asset_id: Asset.where.not(barcode_bkp: nil), format: 0).destroy_all
  end
end
