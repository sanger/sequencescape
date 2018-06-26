#!/usr/bin/env ruby
require_relative 'uat_filters'
# This script is massively faster than using grep as it allows us to do a single simple reg ex.
while line = gets
  match = /^INSERT INTO `([^`]+)`/.match(line)
  next if match && UATFilters::FILTERED_TABLES.include?(match[1])
  puts line
end
