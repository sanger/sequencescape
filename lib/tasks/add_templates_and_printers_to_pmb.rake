# frozen_string_literal: true
require_relative '../label_printer/label_printer'
require_relative '../../config/config'

namespace :pmb do
  task add_label_templates: :environment do
    class LabelTemplateCreator # rubocop:todo Style/Documentation
      attr_accessor :label_types

      class << self
        def label_template_url
          "#{LabelPrinter::PmbClient.base_url_v1}/label_templates"
        end

        def label_type_url
          "#{LabelPrinter::PmbClient.base_url_v1}/label_types"
        end

        attr_reader :label_types

        def label_type_params(label_type_name)
          label_params = {
            plate: {
              data: {
                attributes: {
                  name: 'Plate',
                  feed_value: '008',
                  fine_adjustment: '04',
                  pitch_length: '0110',
                  print_width: '0920',
                  print_length: '0080'
                }
              }
            },
            tube: {
              data: {
                attributes: {
                  name: 'Tube',
                  feed_value: '008',
                  fine_adjustment: '10',
                  pitch_length: '0430',
                  print_width: '0300',
                  print_length: '0400'
                }
              }
            },
            'plate - 6mm': {
              data: {
                attributes: {
                  name: 'plate - 6mm',
                  feed_value: '008',
                  fine_adjustment: '04',
                  pitch_length: '0130',
                  print_width: '0680',
                  print_length: '0060'
                }
              }
            }
          }
          label_params[label_type_name.to_sym]
        end

        def get_label_types
          res = RestClient.get(label_type_url, LabelPrinter::PmbClient.headers_v1)
          @label_types = get_names_and_ids(res)
        end

        def get_label_type_id(name)
          return label_types[name.downcase] if label_types.include? name.downcase

          label_type = label_type_params(name)
          res = RestClient.post(label_type_url, label_type.to_json, LabelPrinter::PmbClient.headers_v1)
          JSON.parse(res)['data']['id']
        end

        def sqsc_96plate_label_template
          label_type_id = get_label_type_id('Plate')
          {
            'data' => {
              'attributes' => {
                'name' => 'sqsc_96plate_label_template',
                'label_type_id' => label_type_id,
                'labels_attributes' => [
                  {
                    'name' => 'main_label',
                    'bitmaps_attributes' => [
                      {
                        'x_origin' => '0030',
                        'y_origin' => '0035',
                        'field_name' => 'top_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0030',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0500',
                        'y_origin' => '0035',
                        'field_name' => 'top_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0500',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0750',
                        'y_origin' => '0035',
                        'field_name' => 'top_far_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0750',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_far_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0890',
                        'y_origin' => '0065',
                        'field_name' => 'label_counter_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '33'
                      }
                    ],
                    'barcodes_attributes' => [
                      {
                        'x_origin' => '0200',
                        'y_origin' => '0000',
                        'field_name' => 'barcode',
                        'barcode_type' => '5',
                        'one_module_width' => '02',
                        'height' => '0070',
                        'rotational_angle' => nil,
                        'one_cell_width' => nil,
                        'type_of_check_digit' => '2',
                        'bar_height' => nil,
                        'no_of_columns' => nil
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def sqsc_96plate_label_template_code39
          label_type_id = get_label_type_id('Plate')
          {
            'data' => {
              'attributes' => {
                'name' => 'sqsc_96plate_label_template_code39',
                'label_type_id' => label_type_id,
                'labels_attributes' => [
                  {
                    'name' => 'main_label',
                    'bitmaps_attributes' => [
                      {
                        'x_origin' => '0030',
                        'y_origin' => '0035',
                        'field_name' => 'top_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0030',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0570',
                        'y_origin' => '0035',
                        'field_name' => 'top_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0570',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0750',
                        'y_origin' => '0035',
                        'field_name' => 'top_far_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0750',
                        'y_origin' => '0065',
                        'field_name' => 'bottom_far_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0890',
                        'y_origin' => '0065',
                        'field_name' => 'label_counter_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '33'
                      }
                    ],
                    'barcodes_attributes' => [
                      {
                        'x_origin' => '0200',
                        'y_origin' => '0000',
                        'field_name' => 'barcode',
                        'barcode_type' => 'B',
                        'one_module_width' => '02',
                        'height' => '0070',
                        'rotational_angle' => '0',
                        'one_cell_width' => nil,
                        'type_of_check_digit' => '1',
                        'bar_height' => nil,
                        'no_of_columns' => nil,
                        'narrow_bar_width' => '01',
                        'narrow_space_width' => '01',
                        'wide_bar_width' => '03',
                        'wide_space_width' => '03',
                        'char_to_char_space_width' => '03'
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def sqsc_384plate_label_template
          label_type_id = get_label_type_id('Plate')
          {
            'data' => {
              'attributes' => {
                'name' => 'sqsc_384plate_label_template',
                'label_type_id' => label_type_id,
                'labels_attributes' => [
                  {
                    'name' => 'main_label',
                    'bitmaps_attributes' => [
                      {
                        'x_origin' => '0140',
                        'y_origin' => '0035',
                        'field_name' => 'top_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '03',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0140',
                        'y_origin' => '0070',
                        'field_name' => 'bottom_left',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '03',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0610',
                        'y_origin' => '0035',
                        'field_name' => 'top_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0610',
                        'y_origin' => '0070',
                        'field_name' => 'bottom_right',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      }
                    ],
                    'barcodes_attributes' => [
                      {
                        'x_origin' => '0330',
                        'y_origin' => '0010',
                        'field_name' => 'barcode',
                        'barcode_type' => '5',
                        'one_module_width' => '02',
                        'height' => '0070',
                        'rotational_angle' => nil,
                        'one_cell_width' => nil,
                        'type_of_check_digit' => '2',
                        'bar_height' => nil,
                        'no_of_columns' => nil
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def tube_label_template_1d
          label_type_id = get_label_type_id('Tube')
          {
            'data' => {
              'attributes' => {
                'name' => 'tube_label_template_1d',
                'label_type_id' => label_type_id,
                'labels_attributes' => [
                  {
                    'name' => 'main_label',
                    'bitmaps_attributes' => [
                      {
                        'x_origin' => '0038',
                        'y_origin' => '0210',
                        'field_name' => 'third_line',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '05',
                        'font' => 'H',
                        'space_adjustment' => '03',
                        'rotational_angles' => '11'
                      },
                      {
                        'x_origin' => '0070',
                        'y_origin' => '0210',
                        'field_name' => 'second_line',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '05',
                        'font' => 'H',
                        'space_adjustment' => '02',
                        'rotational_angles' => '11'
                      },
                      {
                        'x_origin' => '0120',
                        'y_origin' => '0210',
                        'field_name' => 'first_line',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '05',
                        'font' => 'H',
                        'space_adjustment' => '02',
                        'rotational_angles' => '11'
                      },
                      {
                        'x_origin' => '0240',
                        'y_origin' => '0165',
                        'field_name' => 'round_label_top_line',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      },
                      {
                        'x_origin' => '0220',
                        'y_origin' => '0193',
                        'field_name' => 'round_label_bottom_line',
                        'horizontal_magnification' => '05',
                        'vertical_magnification' => '1',
                        'font' => 'G',
                        'space_adjustment' => '00',
                        'rotational_angles' => '00'
                      }
                    ],
                    'barcodes_attributes' => [
                      {
                        'x_origin' => '0043',
                        'y_origin' => '0100',
                        'field_name' => 'barcode',
                        'barcode_type' => '5',
                        'one_module_width' => '01',
                        'height' => '0100',
                        'rotational_angle' => nil,
                        'one_cell_width' => nil,
                        'type_of_check_digit' => '2',
                        'bar_height' => nil,
                        'no_of_columns' => nil
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def swipecard_barcode_template
          {
            data: {
              attributes: {
                name: 'swipecard_barcode_template',
                label_type_id: get_label_type_id('Plate'),
                labels_attributes: [
                  {
                    name: 'main',
                    bitmaps_attributes: [
                      {
                        horizontal_magnification: '1',
                        vertical_magnification: '1',
                        font: 'N',
                        space_adjustment: '00',
                        rotational_angles: '00',
                        x_origin: '0050',
                        y_origin: '0050',
                        field_name: 'left_text'
                      }
                    ],
                    barcodes_attributes: [
                      {
                        barcode_type: '9',
                        one_module_width: '02',
                        height: '0070',
                        rotational_angle: nil,
                        one_cell_width: nil,
                        type_of_check_digit: nil,
                        no_of_columns: nil,
                        bar_height: nil,
                        x_origin: '0300',
                        y_origin: '0010',
                        field_name: 'barcode'
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def plate_6mm_double
          {
            data: {
              attributes: {
                name: 'plate_6mm_double',
                label_type_id: get_label_type_id('plate - 6mm'),
                labels_attributes: [
                  {
                    name: 'main_label',
                    bitmaps_attributes: [
                      {
                        x_origin: '0010',
                        y_origin: '0040',
                        field_name: 'left_text',
                        horizontal_magnification: '08',
                        vertical_magnification: '09',
                        font: 'N',
                        space_adjustment: '00',
                        rotational_angles: '00'
                      },
                      {
                        x_origin: '0470',
                        y_origin: '0040',
                        field_name: 'right_text',
                        horizontal_magnification: '08',
                        vertical_magnification: '09',
                        font: 'N',
                        space_adjustment: '00',
                        rotational_angles: '00'
                      }
                    ],
                    barcodes_attributes: [
                      {
                        x_origin: '0210',
                        y_origin: '0000',
                        field_name: 'barcode',
                        barcode_type: '5',
                        one_module_width: '02',
                        height: '0050',
                        rotational_angle: nil,
                        one_cell_width: nil,
                        type_of_check_digit: '2',
                        bar_height: nil,
                        no_of_columns: nil
                      }
                    ]
                  },
                  {
                    name: 'extra_label',
                    bitmaps_attributes: [
                      {
                        x_origin: '0010',
                        y_origin: '0035',
                        field_name: 'left_text',
                        horizontal_magnification: '05',
                        vertical_magnification: '06',
                        font: 'N',
                        space_adjustment: '00',
                        rotational_angles: '00'
                      },
                      {
                        x_origin: '0150',
                        y_origin: '0035',
                        field_name: 'right_text',
                        horizontal_magnification: '06',
                        vertical_magnification: '07',
                        font: 'N',
                        space_adjustment: '00',
                        rotational_angles: '00'
                      }
                    ]
                  }
                ]
              }
            }
          }
        end

        def get_label_templates
          res = RestClient.get(label_template_url, LabelPrinter::PmbClient.headers_v1)
          get_names_and_ids(res)
        end

        def create_label_template(name)
          puts "Creating template: #{name}"
          label_template = eval name
          RestClient.post(label_template_url, label_template.to_json, LabelPrinter::PmbClient.headers_v1)
        end

        def get_names_and_ids(res)
          JSON.parse(res)['data'].to_h { |label_type| [label_type['attributes']['name'].downcase, label_type['id']] }
        end

        def register_label_template(template)
          template = template[:type]&.first
          if template.present?
            puts "Registering template: #{template[:name]}"
            template.label_template_name = template[:name]
            template.save!
          end
        end

        def execute
          unregistered_templates = [
            { name: 'sqsc_96plate_label_template', type: BarcodePrinterType96Plate },
            { name: 'sqsc_96plate_label_template_code39', type: BarcodePrinterType96Plate },
            { name: 'tube_label_template_1d', type: BarcodePrinterType1DTube },
            { name: 'sqsc_384plate_label_template', type: BarcodePrinterType384Plate },
            { name: 'plate_6mm_double', type: BarcodePrinterType384DoublePlate },
            { name: 'swipecard_barcode_template', type: nil }
          ]
          get_label_types
          registered_templates = get_label_templates
          unregistered_templates.each do |template|
            unless registered_templates.key?(template[:name])
              create_label_template(template[:name])
              register_label_template(template)
            end
          end
        end
      end
    end

    LabelTemplateCreator.execute
  end

  task add_printers: :environment do
    def register_printer(name)
      RestClient.post(
        printer_url,
        { 'data' => { 'attributes' => { 'name' => name } } },
        LabelPrinter::PmbClient.headers_v1
      )
    end

    def get_pmb_printers_names
      res = RestClient.get(printer_url, LabelPrinter::PmbClient.headers_v1)
      JSON.parse(res)['data'].map { |printer| printer['attributes']['name'] }
    end

    def printer_url
      "#{LabelPrinter::PmbClient.base_url_v1}/printers"
    end

    def add_printers
      sqsc_printers_names = BarcodePrinter.all.map(&:name)
      unregistered_printers = sqsc_printers_names - get_pmb_printers_names
      unregistered_printers.each { |name| register_printer(name) } unless unregistered_printers.empty?
    end

    add_printers
  end
end
