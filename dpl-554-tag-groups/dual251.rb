#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'yaml'

CSV_FILE_PATH = '000 10x Tagsets - PN-1000251_ Dual Index Kit TS, Set A.csv'

start_row_index = 4 # zero-based

rows = CSV.read(CSV_FILE_PATH).each_with_index.with_object([]) do |(row, row_index), obj|
  next if row_index < start_row_index
  obj << row
end

names = {
  1 => 'Dual Index Kit TS, Set A 1000251 i7',
  2 => 'Dual Index Kit TS, Set A 1000251 i5 (Workflow A)',
  3 => 'Dual Index Kit TS, Set A 1000251 i5 (Workflow B)'
}

all_tags = {1 => [], 2 => [], 3 => []}

(1..3).each do |group|  # ignore first column]
  (0..11).each do |well_column| # zero-based
    (0..7).each do |well_row| # zero-based
      all_tags[group] << rows[well_column + (well_row * 12)][group]
    end
  end
end

names.each do | group, name |
  record = {
    name => {
      'adapter_type_name' => 'Chromium',
      'tags' => all_tags[group].map.with_index { |tag, index| [index + 1, tag] }.to_h
    }
  }

  yaml_output = record.to_yaml
  puts yaml_output
end
