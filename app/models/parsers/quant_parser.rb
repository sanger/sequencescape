# frozen_string_literal: true
class Parsers::QuantParser
  class InvalidFile < StandardError
  end

  HEADER_IDENTIFIER = 'Headers'
  LOCATION_HEADER = 'Well Location'
  COLUMN_MAPS = {
    'concentration' => %w[concentration ng/ul],
    'molarity' => %w[molarity nmol/l],
    'volume' => %w[volume ul],
    'rin' => %w[RIN RIN]
  }.freeze

  # Extract decimals from columns.
  # Ignores preceding ( and allows optional decimal point
  # Any characters after the digits are ignored.
  # eg.
  # 12.345 => 12.345
  # 13 => 13
  # (45.2) => 45.2
  # sausages => nil
  # 34 ng/ul => 35
  VALUE_REGEX = /\A\({0,1}(?<decimal>\d+\.{0,1}\d*)/

  class_attribute :assay_type, :assay_version

  self.assay_type = 'QuantEssential'
  self.assay_version = 'v0.1'

  def initialize(content)
    @content = content
  end

  def self.headers_index(content)
    content.find_index { |l| l[0] == HEADER_IDENTIFIER }
  end

  def self.parses?(content)
    (content[0][0] == 'Assay Plate Barcode') && headers_index(content)
  end

  def each_well_and_parameters
    data_section.each do |row|
      # If location is nil or blank, ignore the row
      next if row[location_index].nil? || row[location_index].strip.blank?

      yield(row[location_index], qc_values_for_row(row))
    end
  end

  private

  def location_index
    @location_index ||= headers_section.find_index { |cell| cell == LOCATION_HEADER }
  end

  def headers_section
    @content[headers_index + 1]
  end

  def data_section
    @content.slice(headers_index + 2, @content.length)
  end

  def column_maps
    COLUMN_MAPS
  end

  def header_options
    @header_options ||=
      headers_section
        .each_with_object([])
        .with_index do |(description, array), index|
          key, units = column_maps[description&.strip&.downcase]
          next if key.nil? # Our column is not one we are interested in

          array << [key, units, index]
        end
  end

  def qc_values_for_row(row)
    header_options.each_with_object({}) do |(key, units, index), hash|
      matches = VALUE_REGEX.match(row[index])
      next if matches.nil?

      hash[key] = Unit.new(matches[:decimal].to_f, units)
    end
  end

  def headers_index
    @headers_index ||= self.class.headers_index(@content)
  end
end
