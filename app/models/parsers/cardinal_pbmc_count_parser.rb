# frozen_string_literal: true
module Parsers
  # A parser for the cardinal pipeline qc file
  class CardinalPbmcCountParser
    class_attribute :assay_type, :assay_version

    HEADERS = [
      'Well Name',
      'Live Count',
      'Live Cells/mL',
      'Live Mean Size',
      'Viability',
      'Dead Count',
      'Dead Cells/mL',
      'Dead Mean Size',
      'Total Count',
      'Total Cells/mL',
      'Total Mean Size',
      'Note:',
      'Errors:'
    ].freeze

    self.assay_type = 'Cardinal_PBMC_Count'
    self.assay_version = 'v1.0'

    def self.parses?(content)
      content.split('\r\n')[0][0] == HEADERS
    end

    attr_reader :content

    def initialize(content)
      @content = content
    end

    def rows
      @rows ||= content.drop(1)
    end

    # 0 - well name
    # 2 - cell count
    # 4 - viability
    def qc_data
      @qc_data ||=
        {}.tap do |qc_data|
          rows.each do |row|
            next if empty_row?(row)

            well = get_well_location(row[0])
            qc_data[well] = qc_metrics_hash(row)
          end
        end
    end

    def empty_row?(row)
      row[0].blank?
    end

    def get_well_location(cell)
      cell.split(':')[1]
    end

    def each_well_and_parameters(&)
      qc_data.each(&)
    end

    def qc_metrics_hash(row)
      {}.tap do |hash|
        hash[:live_cell_count] = Unit.new(row[2], 'cells')
        viability = row[4]
        hash[:viability] = Unit.new(viability) unless viability == 'NaN'
      end
    end
  end
end
