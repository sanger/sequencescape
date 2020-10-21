# frozen_string_literal: true

# Class to test SPrint.
class Sprint < ApplicationRecord
  # rubocop:disable Rails/Output
  require 'uri'

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

    # Using heron-bc1 for proof of concept.
    printer = 'heron-bc1'

    print_request = {
      "layouts": [
        {
          "labelSize": {
            "width": 23,
            "height": 19,
            "displacement": 22
          },
          "barcodeFields": [
            {
              "x": 15,
              "y": 5,
              "cellWidth": 0.4,
              "barcodeType": 'datamatrix',
              "value": '#barcode#'
            }
          ],
          "textFields": [
            {
              "x": 1,
              "y": 4,
              "value": '#barcode_text#',
              "font": 'proportional',
              "fontSize": 2.9
            },
            {
              "x": 1,
              "y": 8,
              "value": '#date#',
              "font": 'proportional',
              "fontSize": 1.8
            }
          ]
        }
      ]
    }

    body = {
      "query": query,
      "variables": {
        "printer": printer,
        "printRequest": print_request
      }
    }

    reponse = Net::HTTP.post URI(configatron.sprint_url),
                             body.to_json,
                             'Content-Type' => 'application/json'

    puts reponse.body
    # rubocop:enable Rails/Output
  end
end
