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

    set_tube_pmb_config

    @printer_name = 'stub' # comment out to do real tests
    Sprint.send_print_request(@printer_name, @label_template_name, @field_values)
  end

  # *************** 96  ***************
  def set_plate96_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_text: 'DN111111', workline_identifier: 'DN111111', order_role: 'Heron', plate_purpose: 'LHR PCR 1' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_text: 'DN222222', workline_identifier: 'DN222222', order_role: 'Heron 2', plate_purpose: 'LHR PCR 2' }
    ]
    @printer_name = 'heron-bc1'
    @label_template_name = 'plate_96.yml.erb'
  end

  def set_plate96_pmb_config
    @field_values = [
      { barcode: 'DN111111', top_left: '1-APR-2020', bottom_left: 'DN111111', top_right: 'DN111111', bottom_right: 'Heron LHR PCR 1' },
      { barcode: 'DN222222', top_left: '2-APR-2020', bottom_left: 'DN222222', top_right: 'DN222222', bottom_right: 'Heron 2 LHR PCR 2' }
    ]
    @printer_name = 'heron-bc1'
    @label_template_name = 'plate_96_pmb.yml.erb'
  end

  # *************** 384 ***************
  def set_plate_384_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_text: 'DN111111', workline_identifier: 'DN111111', order_role: 'Heron', plate_purpose: 'LHR PCR 1' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_text: 'DN222222', workline_identifier: 'DN222222', order_role: 'Heron 2', plate_purpose: 'LHR PCR 2' }
    ]
    @printer_name = 'heron-bc2'
    @label_template_name = 'plate_384.yml.erb'
  end

  def set_plate_384_pmb_1_config
    @field_values = [
      { barcode: 'DN111111', left_text: 'DN111111', right_text: 'DN111111' },
      { barcode: 'DN222222', left_text: 'DN222222', right_text: 'DN222222' }
    ]
    @printer_name = 'heron-bc2'
    @label_template_name = 'plate_384_pmb_1.yml.erb'
  end

  def set_plate_384_pmb_2_config
    @field_values = [
      { left_text: '1-APR-2020', right_text: 'DN111111 Heron LHR PCR 1' },
      { left_text: '2-APR-2020', right_text: 'DN222222 Heron 2 LHR PCR 2' }
    ]
    @printer_name = 'heron-bc2'
    @label_template_name = 'plate_384_pmb_2.yml.erb'
  end

  # *************** tube ***************
  def set_tube_config
    @field_values = [
      { barcode: 'DN111111', date: '1-APR-2020', barcode_number_and_pools_number: '111111 1', labware_name: 'LName1', tube_purpose: 'TPurpose1', top_line: 'NT', bottom_line: 'NT111111' },
      { barcode: 'DN222222', date: '2-APR-2020', barcode_number_and_pools_number: '222222 2', labware_name: 'LName2', tube_purpose: 'TPurpose2', top_line: 'NT', bottom_line: 'NT111111' }
    ]
    @printer_name = 'heron-bc7'
    @label_template_name = 'tube.yml.erb'
  end

  def set_tube_pmb_config
    @field_values = [
      { barcode: 'DN111111', first_line: '111111 A1:P24', second_line: '1111111, P384', third_line: 'LHR-384 Lib Pool', fourth_line: '1-APR-2020', round_label_top_line: 'NT', round_label_bottom_line: 'NT111111' },
      { barcode: 'DN222222', first_line: '222222 A2:P24', second_line: '2222222, P384', third_line: 'LHR-384 Lib Pool', fourth_line: '2-APR-2020', round_label_top_line: 'NT', round_label_bottom_line: 'NT222222' }
    ]
    @printer_name = 'heron-bc7'
    @label_template_name = 'tube_pmb.yml.erb'
  end

  # test_config variables
  # date = "date placeholder"
  # barcode = "barcode placeholder"
  # barcode_text = "barcode_text placeholder"

  # rubocop:enable Rails/Output
end
