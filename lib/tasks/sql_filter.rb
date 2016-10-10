#!/usr/bin/env ruby
#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014 Genome Research Ltd.
require_relative 'uat_filters'
# This script is massively faster than using grep as it allows us to do a single simple reg ex.
while line = gets
  match = /^INSERT INTO `([^`]+)`/.match(line)
  next if match && UATFilters::FILTERED_TABLES.include?(match[1])
  puts line
end
