# frozen_string_literal: true

# Rails task to add missing asset audit records from a CSV file
namespace :asset_audit do
  # This rake task is used to add missing asset audit records from a CSV file.
  # If there are any errors in the CSV file, no records will be inserted.
  # Usage: rails asset_audit:add_missing_records['/path/to/file.csv']
  # The CSV file should have the following headers:
  # barcode, message, created_by, created_at
  # The message column should have one of the following values:
  # 'Destroying location', 'Destroying labware'

  desc 'Add missing asset audit records'
  task :add_missing_records, [:file_path] => :environment do |_, args|
    required_csv_headers = %w[barcode message created_by created_at]

    # Check if the file path is provided and valid
    file_path = args[:file_path] == 'nil' ? nil : args[:file_path]
    if file_path.nil? || !File.exist?(file_path)
      puts 'Please provide a valid file path'
      next
    end

    # Read the CSV file and validate the headers
    begin
      csv_data = CSV.read(file_path, headers: true)
    rescue StandardError => e
      puts "Failed to read CSV file: #{e.message}"
      next
    end

    unless csv_data.headers.length == required_csv_headers.length
      puts 'Failed to read CSV file: Invalid number of header columns'
      next
    end

    # Process the CSV data and create asset audit records data array to insert
    asset_audit_data = []
    csv_data.each do |row|
      missing_columns = required_csv_headers.select { |header| row[header].nil? }

      # Check if any of the required columns are missing
      unless missing_columns.empty?
        puts 'Failed to read CSV file: Missing columns'
        next
      end

      # Find the asset by barcode
      asset = Labware.find_by_barcode(row['barcode'].strip)
      if asset.nil?
        puts "Asset with barcode #{row['barcode']} not found."
        next
      end

      # Check if the message is valid
      key =
        case row['message']
        when 'Destroying location'
          'destroy_location'
        when 'Destroying labware'
          'destroy_labware'
        end

      if key.nil?
        puts "Invalid message for asset with barcode #{row['barcode']}."
        next
      end

      # Create the asset audit record data
      data = {
        asset_id: asset.id,
        created_by: row['created_by'],
        created_at: row['created_at'],
        message: "Process '#{row['message']}' performed on instrument Destroying instrument",
        key: key
      }
      asset_audit_data << data
    end

    # Insert the asset audit records
    ActiveRecord::Base.transaction do
      asset_audit_data.each do |data|
        AssetAudit.create!(
          message: data[:message],
          created_by: data[:created_by],
          created_at: data[:created_at],
          asset_id: data[:asset_id],
          key: data[:key]
        )
      end
      puts 'All records successfully inserted.'
    rescue ActiveRecord::ActiveRecordError => e
      puts "Failed to insert records: #{e.message}"
      raise ActiveRecord::Rollback
    end
  end
end
