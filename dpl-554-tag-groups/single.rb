#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'yaml'

csv_file_path = '000 10x Tagsets - PN-1000212 Single Index Kit N Set A.csv'
tag_group_name = 'Single Index Kit N, Set A 1000212'

record = {
  tag_group_name => {
    'adapter_type_name' => 'Chromium',
    'tags' => {}
  }
}

CSV.foreach(csv_file_path).with_index do |row, row_index| # zero-based
  (1..4).each do |column_index|
    map_id = (row_index * 4) + column_index
    record[tag_group_name]['tags'][map_id] = row[column_index]  # skip the first column
  end
end

# Convert the hash to YAML
yaml_output = record.to_yaml

# Print the YAML output
puts yaml_output
