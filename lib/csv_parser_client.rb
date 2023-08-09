# frozen_string_literal: true

# For communicating with the csv-parser microservice (https://github.com/sanger/csv-parser)
module CsvParserClient
  require 'uri'

  # rubocop:todo Metrics/MethodLength
  def self.get_tube_rack_scan_results(tube_rack_barcode, object_to_add_errors_to) # rubocop:todo Metrics/AbcSize
    endpoint = configatron.tube_rack_scans_microservice_url
    response = Net::HTTP.get_response(URI(endpoint + tube_rack_barcode))

    if response.body.nil?
      error_message =
        # rubocop:todo Layout/LineLength
        "Scan could not be retrieved for tube rack with barcode #{tube_rack_barcode}. Service responded with status code #{response.code}"

      # rubocop:enable Layout/LineLength
      error_message += " and message #{response.message}."
      object_to_add_errors_to.errors.add(:base, error_message)
      return nil
    end

    begin
      scan_results = JSON.parse(response.body)
    rescue JSON::JSONError => e
      error_message =
        # rubocop:todo Layout/LineLength
        "Response when trying to retrieve scan (tube rack with barcode #{tube_rack_barcode}) was not valid JSON so could not be understood. Error message: #{e.message}"

      # rubocop:enable Layout/LineLength
      object_to_add_errors_to.errors.add(:base, error_message)
      return nil
    end

    unless response.code == '200'
      error_message =
        # rubocop:todo Layout/LineLength
        "Scan could not be retrieved for tube rack with barcode #{tube_rack_barcode}. Service responded with status code #{response.code}"

      # rubocop:enable Layout/LineLength
      error_message += " and the following message: #{scan_results['error']}"
      object_to_add_errors_to.errors.add(:base, error_message)
      return nil
    end
    return nil unless scan_results.key?('layout')

    tube_barcode_to_coordinate_without_no_reads = remove_no_read_results(scan_results['layout'])
    tube_barcode_to_coordinate_without_no_reads || nil
  end

  # rubocop:enable Metrics/MethodLength

  def self.remove_no_read_results(tube_barcode_to_coordinate)
    tube_barcode_to_coordinate&.reject! { |key| no_read?(key) } unless tube_barcode_to_coordinate.nil? # rubocop:todo Style/SafeNavigation
    tube_barcode_to_coordinate
  end

  def self.no_read?(value_to_check)
    return true if value_to_check.casecmp('no read').zero?

    false
  end
end
