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
    # printer_name = 'stub'

    set_plate96_config
    Sprint.send_print_request(@printer_name, @label_template_name, @field_values)
  end

  def set_plate96_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_text: 'DN111111', workline_identifier: 'DN111111', order_role: 'Heron', plate_purpose: 'LHR PCR 1' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_text: 'DN222222', workline_identifier: 'DN222222', order_role: 'Heron 2', plate_purpose: 'LHR PCR 2' }
    ]
    @printer_name = 'heron-bc1'
    @label_template_name = 'plate_96.yml.erb'
  end

  def set_plate_384_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_text: 'DN111111', workline_identifier: 'DN111111', order_role: 'Heron', plate_purpose: 'LHR PCR 1' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_text: 'DN222222', workline_identifier: 'DN222222', order_role: 'Heron 2', plate_purpose: 'LHR PCR 2' }
    ]
    @printer_name = 'heron-bc2'
    @label_template_name = 'plate_384.yml.erb'
  end

  def set_tube_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_text: 'DN111111', barcode_number_and_pools_number: '111111 1', labware_name: 'LName1', tube_purpose: 'TPurpose1' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_text: 'DN222222', barcode_number_and_pools_number: '222222 2', labware_name: 'LName2', tube_purpose: 'TPurpose2' }
    ]
    @printer_name = 'heron-bc7'
    @label_template_name = 'tube.yml.erb'
  end

  # test_config variables
  # date = "date placeholder"
  # barcode = "barcode placeholder"
  # barcode_text = "barcode_text placeholder"

  # rubocop:enable Rails/Output
end
