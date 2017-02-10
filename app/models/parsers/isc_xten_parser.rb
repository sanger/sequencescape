# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class Parsers::IscXtenParser
  class InvalidFile < StandardError; end

  def headers
    @content[0]
  end

  def table
    @content.slice(1, @content.length)
  end

  def get_row(location)
    letter = location[0].chr
    num = location.slice(1, location.length)
    table.detect do |row|
      row[0] == letter && row[1] == num
    end
  end

  def concentration(location)
    begin
      get_row(location)[get_column_for_header(:concentration)]
    rescue NoMethodError # Ugh! I want to catch these where they happen
      raise InvalidFile
    end
  end

  def get_column_for_header(sym)
    headers.each_with_index do |h, pos|
      name = get_name_for_header(sym)
      unless name.nil? || h.nil?
        return pos if h.squish == name.squish
      end
    end
  end

  def get_name_for_header(sym_name)
    {
      row: 'Well Row',
      col: 'Well Col',
      content: 'Content',
      raw_data: 'Raw Data (485/520)',
      concentration: 'Linear regression fit based on Raw Data (485/520)'
    }[sym_name]
  end

  def self.is_isc_xten_file?(content)
    parser = Parsers::IscXtenParser.new(content)
    [:row, :col, :content, :raw_data, :concentration].each_with_index.map do |sym, pos|
      parser.get_column_for_header(sym) == pos
    end.all?
  end

  def initialize(content)
    @content = content
  end

  def locations
    table.sort { |a, b| a[0] <=> b[0] && a[1].to_i <=> b[1].to_i }.map { |l| l[0] + l[1] }
  end

  def each_well_and_parameters
    locations.each do |location_name|
      yield(location_name, { set_concentration: concentration(location_name) })
    end
  end
end
