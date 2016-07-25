require_relative '../label_printer/label_printer'
require_relative '../../config/config'

namespace :pmb do
  task :add_label_templates do
    label_template_url = "#{LabelPrinter::PmbClient.base_url}/label_templates"
    label_type_url = "#{LabelPrinter::PmbClient.base_url}/label_types"

    label_type_plate = {"data" =>
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
    begin
      res = RestClient.post(label_type_url, label_type_plate.to_json, LabelPrinter::PmbClient.headers)
      label_type_plate_id = JSON.parse(res)["data"]["id"]
      p "Label type for plate was created"
    rescue RestClient::UnprocessableEntity => e
      p "Label type for plate errors: #{LabelPrinter::PmbClient.pretty_errors(e.response)}"
      label_type_plate_id = 1
    end

    label_template_plate = {"data" =>
                              {"attributes" =>
                                {"name" => "ss_plate_label_template",
                                  "label_type_id" => label_type_plate_id,
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

    begin
      RestClient.post(label_template_url, label_template_plate.to_json, LabelPrinter::PmbClient.headers)
      p "Label template for plate was created"
    rescue RestClient::UnprocessableEntity => e
      p "Label template for plate errors: #{LabelPrinter::PmbClient.pretty_errors(e.response)}"
    end

    label_type_tube = {"data" =>
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

    begin
      res = RestClient.post(label_type_url, label_type_tube.to_json, LabelPrinter::PmbClient.headers)
      label_type_tube_id = JSON.parse(res)["data"]["id"]
      p "Label type for tube was created"
    rescue RestClient::UnprocessableEntity => e
      p "Label type for tube errors: #{LabelPrinter::PmbClient.pretty_errors(e.response)}"
    end

    label_template_tube = {"data" =>
                            {"attributes" =>
                              {"name" => "ss_tube_label_template",
                                "label_type_id" =>  label_type_tube_id,
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
    begin
      RestClient.post(label_template_url, label_template_tube.to_json, LabelPrinter::PmbClient.headers)
      p "Label template for tube was created"
    rescue RestClient::UnprocessableEntity => e
      p "Label template for tube errors: #{LabelPrinter::PmbClient.pretty_errors(e.response)}"
    end
  end
end
