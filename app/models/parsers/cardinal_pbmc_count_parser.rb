# frozen_string_literal: true
module Parsers
  # A parser for the cardinal pipeline qc file
  class CardinalPbmcCountParser
    class_attribute :assay_type, :assay_version

    HEADERS = ['Well Name', 'Live Count', 'Live Cells/mL', 'Live Mean Size', 'Viability', 'Dead Count', 'Dead Cells/mL', 'Dead Mean Size', 'Total Count', 'Total Cells/mL', 'Total Mean Size', 'Note:', 'Errors:'].freeze

    self.assay_type = 'Cardinal_PBMC_Count'
    self.assay_version = 'v1.0'

    def self.parses?(content)
      content.split('\r\n')[0][0] == HEADERS
    end

    attr_reader :content

    def initialize(content)
      @content = content
    end

    def csv
      @csv ||= CSV.parse(content, headers: true)
    end

    def qc_data
      @qc_data ||=
        {}.tap do |qc_data|
          csv.each do |row|
            hsh = row.to_h
            qc_data[hsh['Well Name']] = {
              viability: Unit.new(hsh['Viability']),
              live_cell_count: Unit.new(hsh['Live Cells/mL'], 'cells')
            }
          end
        end
    end

    def each_well_and_parameters(&block)
      qc_data.each(&block)
    end
  end
end
