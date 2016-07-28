require_relative '../label_printer/label_printer'
require_relative '../../config/config'

namespace :pmb do
  task :add_label_templates => :environment do

    class LabelTemplateCreator

      attr_accessor :label_types

      class << self

        def label_template_url
          "#{LabelPrinter::PmbClient.base_url}/label_templates"
        end

        def label_type_url
          "#{LabelPrinter::PmbClient.base_url}/label_types"
        end

        def label_types
          @label_types
        end

        def label_type_plate
          {"data" =>
            {"attributes" =>
              {"name" => "Plate",
                "feed_value" => "008",
                "fine_adjustment" => "04",
                "pitch_length" => "0110",
                "print_width" => "0920",
                "print_length" => "0080"
              }
            }
          }
        end

        def label_type_tube
          {"data" =>
            {"attributes" =>
              {"name" => "Tube",
                "feed_value" => "008",
                "fine_adjustment" => "10",
                "pitch_length" => "0430",
                "print_width" => "0300",
                "print_length" => "0400"
              }
            }
          }
        end

        def get_label_types
          res = RestClient.get(label_type_url, LabelPrinter::PmbClient.headers)
          @label_types = get_names_and_ids(res)
        end

        def get_label_type_id(name)
          return label_types[name] if label_types.include? name
          label_type = eval "label_type_#{name.downcase}"
          res = RestClient.post(label_type_url, label_type.to_json, LabelPrinter::PmbClient.headers)
          label_type_id = JSON.parse(res)["data"]["id"]
        end

        def sqsc_plate_label_template
          label_type_id = get_label_type_id("Plate")
          {"data" =>
            {"attributes" =>
              {"name" => "sqsc_plate_label_template",
                "label_type_id" => label_type_id,
                "labels_attributes" => [
                  {"name" => "main_label",
                    "bitmaps_attributes" => [
                      {"x_origin" => "0030", "y_origin" => "0035", "field_name" => "top_left", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0030", "y_origin" => "0065", "field_name" => "bottom_left", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0500", "y_origin" => "0035", "field_name" => "top_right", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0500", "y_origin" => "0065", "field_name" => "bottom_right", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0750", "y_origin" => "0035", "field_name" => "top_far_right", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0750", "y_origin" => "0065", "field_name" => "bottom_far_right", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0890", "y_origin" => "0065", "field_name" => "label_counter_right", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "33"}
                    ],
                    "barcodes_attributes"  =>  [
                      {"x_origin" => "0200", "y_origin" => "0000", "field_name" => "barcode", "barcode_type" => "5", "one_module_width" => "02", "height" => "0070", "rotational_angle" => nil, "one_cell_width" => nil, "type_of_check_digit" => "2", "bar_height" => nil, "no_of_columns" => nil}
                    ]
                  }
                ]
              }
            }
          }
        end

        def sqsc_tube_label_template
          label_type_id = get_label_type_id("Tube")
          {"data" =>
            {"attributes" =>
              {"name" => "sqsc_tube_label_template",
                "label_type_id" =>  label_type_id,
                "labels_attributes" => [
                  {"name" =>  "main_label",
                    "bitmaps_attributes"  =>  [
                      {"x_origin" => "0038", "y_origin" => "0210", "field_name" => "bottom_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "03", "rotational_angles" => "11"},
                      {"x_origin" => "0070", "y_origin" => "0210", "field_name" => "middle_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "02", "rotational_angles" => "11"},
                      {"x_origin" => "0120", "y_origin" => "0210", "field_name" => "top_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "02", "rotational_angles" => "11"},
                      {"x_origin" => "0240", "y_origin" => "0165", "field_name" => "round_label_top_line", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"},
                      {"x_origin" => "0220", "y_origin" => "0193", "field_name" => "round_label_bottom_line", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00"}
                    ],
                    "barcodes_attributes"  =>  [
                      {"x_origin" => "0043", "y_origin" => "0100", "field_name" => "barcode", "barcode_type" => "5", "one_module_width" => "01", "height" => "0100", "rotational_angle" => nil, "one_cell_width" => nil, "type_of_check_digit" => "2", "bar_height" => nil, "no_of_columns" => nil}
                    ]
                  }
                ]
              }
            }
          }
        end

        def get_label_templates
          res = RestClient.get(label_template_url, LabelPrinter::PmbClient.headers)
          label_templates = get_names_and_ids(res)
        end

        def create_label_template(name)
          label_template = eval name
          RestClient.post(label_template_url, label_template.to_json, LabelPrinter::PmbClient.headers)
        end

        def get_names_and_ids(res)
          Hash[JSON.parse(res)["data"].map {|label_type| [label_type["attributes"]["name"], label_type["id"]]}]
        end

        def execute
          label_template_plate_name = 'sqsc_plate_label_template'
          label_template_tube_name = 'sqsc_tube_label_template'
          label_templates = get_label_templates
          result = [label_template_plate_name, label_template_tube_name] - label_templates.keys
          unless result.empty?
            get_label_types
            result.each {|name| create_label_template(name)}
          end
          type_tube = BarcodePrinterType1DTube.first
          type_tube.label_template_name = label_template_tube_name
          type_tube.save!
          type_plate = BarcodePrinterType96Plate.first
          type_plate.label_template_name = label_template_plate_name
          type_plate.save!
        end
      end
    end

    LabelTemplateCreator.execute

  end
end
