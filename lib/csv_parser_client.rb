# frozen_string_literal: true

# For communicating with the csv-parser microservice (https://github.com/sanger/csv-parser)
module CsvParserClient
  def self.get_tube_rack_scan_results(tube_rack_barcode, object_to_add_errors_to)
    host_name = Rails.configuration.tube_rack_scans_microservice_endpoint
    path = '/tube_rack/' + tube_rack_barcode
    port = Rails.configuration.tube_rack_scans_microservice_port
    response = Net::HTTP.get_response(host_name, path, port)

    begin
      scan_results = JSON.parse(response.body)
    rescue JSON::JSONError => e
      error_message = "Response when trying to retrieve scan (tube rack with barcode #{tube_rack_barcode}) was not valid JSON so could not be understood. Error message: #{e.message}"
      object_to_add_errors_to.errors.add(:base, error_message)
      return nil
    end

    unless response.code == '200'
      error_message = "Scan could not be retrieved for tube rack with barcode #{tube_rack_barcode}. Service responded with status code #{response.code}"
      error_message += " and the following message: #{scan_results['error']}"
      object_to_add_errors_to.errors.add(:base, error_message)
      return nil
    end

    scan_results['layout'] || nil
  end
end
