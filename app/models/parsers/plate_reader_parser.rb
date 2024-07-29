# frozen_string_literal: true
class Parsers::PlateReaderParser
  class InvalidFile < StandardError
  end

  class_attribute :assay_type, :assay_version

  self.assay_type = 'Plate Reader'
  self.assay_version = 'v0.1'

  def headers
    @content[0]
  end

  def table
    @content.slice(1, @content.length)
  end

  def get_row(location)
    letter = location[0].chr
    num = location.slice(1, location.length)
    table.detect { |row| row[0] == letter && row[1] == num }
  end

  def concentration(location)
    get_row(location)[get_column_for_header(:concentration)]
  rescue NoMethodError # Ugh! I want to catch these where they happen
    raise InvalidFile
  end

  def get_column_for_header(sym)
    headers.each_with_index do |h, pos|
      name = get_name_for_header(sym)
      return pos if h.squish == name.squish unless name.nil? || h.nil?
    end
  end

  def get_name_for_header(sym_name)
    {
      row: 'Well Row',
      col: 'Well Col',
      content: 'Content',
      raw_data: 'Raw Data (485/520)',
      concentration: 'Linear regression fit based on Raw Data (485/520)'
    }[
      sym_name
    ]
  end

  def self.parses?(content)
    parser = Parsers::PlateReaderParser.new(content)
    %i[row col content raw_data concentration]
      .each_with_index
      .map { |sym, pos| parser.get_column_for_header(sym) == pos }
      .all?
  end

  def initialize(content)
    @content = content
  end

  def locations
    table.sort { |a, b| a[0] <=> b[0] && a[1].to_i <=> b[1].to_i }.map { |l| l[0] + l[1] }
  end

  def each_well_and_parameters
    locations.each do |location_name|
      yield(location_name, { 'concentration' => Unit.new(concentration(location_name), 'ng/ul') })
    end
  end
end
