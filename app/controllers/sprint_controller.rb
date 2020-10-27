# frozen_string_literal: true

# Controller to test SPrint
class SprintController < ApplicationController
  # rubocop:disable Rails/Output
  def show
    print '****** show ******'
  end

  def action
    # Using printer called stub which is a fake printer. 
    # This will treat the request like a request to a printer, but not actually try and print anything.
    printer_name = "stub" #"heron-bc1" 
    
    label_template_name = '96_config.yml.erb'

    Sprint.send_print_request(printer_name, label_template_name, x96_values)
  end

  # 96_config variables
  def x96_values
    [
      { barcode: "DN623748I", date: "1-APR-2020", barcode_text: "DN623748I", workline_identifier: "DN623748I", order_role: "Heron", plate_purpose: "LHR PCR 2" },
      { barcode: "xxxDN623748I", date: "xxx1-APR-2020", barcode_text: "xxxDN623748I", workline_identifier: "xxxDN623748I", order_role: "xxxHeron", plate_purpose: "xxxLHR PCR 2" }
    ]
  end

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
    # plate_purpose

    # tube_config variables
    # barcode
    # date
    # tube_purpose
    # barcode_number_and_pools_number
    # labware_name

  # rubocop:enable Rails/Output
end
