# frozen_string_literal: true

# Class to test SPrint.
class Sprint < ApplicationRecord
  # rubocop:disable Rails/Output
  require 'uri'
  require 'erb'

  # Sends a POST print request to SPrint
  # Currently implementing a proof of concept
  # Using HTTP instead of GraphQL client, 'stub' printer and variable placeholders
  def self.print_request
    # GraphQL print mutation
    query = "mutation Print($printRequest: PrintRequest!, $printer: String!) {
      print(printRequest: $printRequest, printer: $printer) {
        jobId
      }
    }"

    # Using printer called stub which is a fake printer. 
    # This will treat the request like a request to a printer, but not actually try and print anything.
    printer = "stub" #heron-bc1

    # test_config variables
    # date = "date placeholder"
    # barcode = "barcode placeholder"
    # barcode_text = "barcode_text placeholder"

    # 384_config variables
    # barcode
    # barcode_text
    # date
    # workline_identifier
    # order_role
    # labware_purpose

    # 96_config variables
    barcode = "DN623748I"
    date = "1-APR-2020"
    barcode_text = "DN623748I"
    workline_identifier = "DN623748I"
    order_role = "Heron LHR PCR 2"

    # tube_config variables
    # barcode
    # date
    # plate_purpose
    # barcode_number_and_pools_number
    # labware_name

    template = ERB.new File.read(File.join('config', 'sprint', '96_config.yml.erb'))
    print_request = YAML.load template.result binding

    body = {
      "query": query,
      "variables": {
        "printer": printer,
        "printRequest": print_request
      }
    }

    puts "body"
    puts body
    
    reponse = Net::HTTP.post URI(configatron.sprint_url),
                             body.to_json,
                             'Content-Type' => 'application/json'

    puts reponse.body
    # rubocop:enable Rails/Output
  end
end
