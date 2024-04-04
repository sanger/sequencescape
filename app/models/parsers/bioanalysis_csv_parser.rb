# frozen_string_literal: true

class Parsers::BioanalysisCsvParser # rubocop:todo Metrics/ClassLength
  class InvalidFile < StandardError
  end

  class_attribute :assay_type, :assay_version

  self.assay_type = 'bioanalyser'
  self.assay_version = 'v0.1'

  attr_reader :content

  def initialize(content)
    @content = content
  end

  def field_name_for(sym_name)
    { concentration: 'Conc. [ng/µl]', molarity: 'Molarity [nmol/l]' }[sym_name]
  end

  def concentration(plate_position)
    get_parsed_attribute(plate_position, field_name_for(:concentration))
  end

  def molarity(plate_position)
    get_parsed_attribute(plate_position, field_name_for(:molarity))
  end

  def table_content_hash(group) # rubocop:todo Metrics/AbcSize
    content_hash = {}
    starting_line = group[0]
    ending_line = group[1]
    type = content[starting_line][0]
    fields = content[starting_line + 1]

    ((starting_line + 2)..(ending_line)).each do |pos|
      values = content[pos]
      content_hash.merge!(fields.zip(values).to_h) unless values.nil? && (values.length != fields.length)
    end
    content_hash
  end

  def build_range(range)
    range = range == nil ? [0, content.length - 1] : range.dup
    range.push(content.length - 1) if (range.length == 1)
    range
  end

  # Finds groups of lines by range in which the beginning of the range contains the
  # matching regexp as text in the first column and the end of the range is an empty line
  # - regexp -> Regular expression to be matched in the first column as beginning of range
  # - range -> In case it is specified, restricts the searching process to this range of lines
  # instead of using all the content of the CSV file
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def get_groups(regexp, range = nil) # rubocop:todo Metrics/CyclomaticComplexity
    groups = []
    group = []
    range = build_range(range)

    group_contents = get_group_content(range)

    group_contents.each_with_index do |line, pos|
      if line[0].present? && line[0].match(regexp) && group.empty?
        group.push(pos)
      elsif (line.empty? && group.one?)
        group.push(pos - 1)
      end

      if group.length == 2
        groups.push [group[0] + range[0], group[1] + range[0]]
        group = []
      end
      groups.push [group[0] + range[0], pos + range[0]] if ((group.length == 1) && (pos == (group_contents.length - 1)))
    end
    groups
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def get_group_content(group)
    content.slice(group[0], group[1] - group[0] + 1)
  end

  def parse_peak_table(group)
    table_content_hash(get_groups(/Peak Table/m, group)[0])
  end

  def parse_region_table(group)
    table_content_hash(get_groups(/Region Table/m, group)[0])
  end

  def parse_overall(group)
    # Number of peaks
    get_group_content(get_groups(/Overall.*/m, group)[0])[1][1]
  end

  def parse_cell(group)
    get_group_content(group)[0][1]
  end

  def parse_sample(group)
    {
      parse_cell(group) => {
        peak_table: parse_peak_table(group),
        region_table: parse_region_table(group),
        overall: parse_overall(group)
      }
    }
  end

  def parse_samples
    groups = get_groups(/Sample Name/)

    groups
      .each_with_index
      .map do |group, pos|
        next_index = (pos == (groups.length - 1)) ? @content.length - 1 : groups[pos + 1][0] - 1
        [group[0], next_index]
      end
      .reduce({}) { |memo, group| memo.merge(parse_sample group) }
  end

  def parsed_content
    @parsed_content ||= parse_samples
  rescue NoMethodError => e # Ugh! I want to catch these where they happen
    raise InvalidFile
  end

  def get_parsed_attribute(plate_position, field)
    return nil if parsed_content.nil? || parsed_content[plate_position].nil?

    parsed_content[plate_position][:peak_table][field]
  end

  def each_well_and_parameters
    parsed_content.each do |well, values|
      yield(
        well,
        {
          'concentration' => Unit.new(values[:peak_table][field_name_for(:concentration)], 'ng/ul'),
          'molarity' => Unit.new(values[:peak_table][field_name_for(:molarity)], 'nmol/l')
        }
      )
    end
  end

  def self.parses?(content)
    # We don't go through the whole file
    content[0..10].detect { |line| line[0]&.include?('Version Created') && /^B.*/ === line[1] }.present?
  end
end
