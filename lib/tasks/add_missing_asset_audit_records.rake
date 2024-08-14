# frozen_string_literal: true

namespace :asset_audit do
  desc 'Add missing asset audit records'
  task :add_missing_records, [:file_path] => :environment do |_, args|
    file_path = args[:file_path]
    if file_path.nil? || !File.exist?(file_path)
      puts 'Please provide a valid file path'
      exit
    end

    puts 'Adding missing asset audit records...'

    ActiveRecord::Base.transaction do
      csv_data = CSV.read(file_path, headers: true)
      csv_data.each do |row|

        asset = Labware.find_by_barcode(row['barcode'].strip)
        next if asset.nil?

        key = case row['message']
              when 'Destroying location'
                'destroy_location'
              when 'Destroying labware'
                'destroy_labware'
              end
        next if key.nil?

        begin
          AssetAudit.create!( message: "Process '#{row['message']}' performed on instrument Destroying instrument",
          created_by: row['created_by'].strip,
          created_at: row['created_at'].strip,
          asset_id: asset.id,
          key:key)
          puts "Record for asset_id #{row['asset_id']} successfully inserted."
        rescue ActiveRecord::ActiveRecordError, StandardError => e
          puts "Error inserting record for asset_id #{row['asset_id']}: #{e.message}"
        end
      end
    end
  end
end
