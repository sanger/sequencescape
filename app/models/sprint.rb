# Class to test Sprint.
class Sprint < ApplicationRecord
  require 'uri'

  def self.print_request
    # rubocop:disable Rails/Output
    puts '****SEND PRINT REQUEST***'
    puts URI(configatron.sprint_url)

    body = {
      "query": 'print',
      "variables": {
        "printer": 'aPrinterName',
        "printRequest": {
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
      }
    }

    puts body
    # rubocop:enable Rails/Output

    # reponse = Net::HTTP.post URI(configatron.sprint_url),
    #            body.to_json,
    #            "Content-Type" => "application/json",
  end
end
