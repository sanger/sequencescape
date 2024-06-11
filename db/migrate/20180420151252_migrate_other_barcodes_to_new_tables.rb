# frozen_string_literal: true

# Move the barcodes from metadata to the new tables.
class MigrateOtherBarcodesToNewTables < ActiveRecord::Migration[5.1]
  def up # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/BlockLength
    Barcode.transaction do
      say 'Migrating Infinium Barcodes'
      Plate::Metadata
        .where.not(infinium_barcode: nil)
        .in_batches
        .each_with_index do |batch, i|
          say "Fetching batch #{i}"
          barcodes = batch.pluck(:plate_id, :infinium_barcode)
          say "From #{barcodes.first.first} to #{barcodes.last.first}"
          say 'Building hashes'
          barcodes_hash = barcodes.map { |asset_id, barcode| { asset_id:, barcode:, format: 1 } }
          say 'Importing'
          Barcode.import(barcodes_hash)
          say 'Imported'
        end
      say 'Finished migrating Infinium Barcodes'
      say 'Migrating Fluidigm barcodes'
      Plate::Metadata
        .where.not(fluidigm_barcode: nil)
        .in_batches
        .each_with_index do |batch, i|
          say "Fetching batch #{i}"
          barcodes = batch.pluck(:plate_id, :fluidigm_barcode)
          say "From #{barcodes.first.first} to #{barcodes.last.first}"
          say 'Building hashes'
          barcodes_hash = barcodes.map { |asset_id, barcode| { asset_id:, barcode:, format: 2 } }
          say 'Importing'
          Barcode.import(barcodes_hash)
          say 'Imported'
        end
      say 'Finished migrating Fluidigm Barcodes'
    end
    # rubocop:enable Metrics/BlockLength
  end

  def down
    # rubocop:disable Rails/PluckInWhere
    Barcode.where(asset_id: Plate::Metadata.where.not(infinium_barcode: nil).pluck(:plate_id), format: 1).destroy_all
    Barcode.where(asset_id: Plate::Metadata.where.not(fluidigm_barcode: nil).pluck(:plate_id), format: 2).destroy_all
    # rubocop:enable Rails/PluckInWhere
  end
end
