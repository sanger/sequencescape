# frozen_string_literal: true
module Parsers
  # A parser for the cardinal pipeline qc file
  class CardinalPbmcCountParser

    class_attribute :assay_type, :assay_version

    self.assay_type = 'Cardinal_PBMC_Count'
    self.assay_version = 'v1.0'

    attr_reader :content

    def initialize(content)
      @content = content
    end

    def csv
      @csv ||= CSV.parse(content, headers: true)
    end

    def qc_data
      @qc_data ||= {}.tap do |qc_data|
        csv.each do |row|
          hsh = row.to_h
          qc_data[hsh['Well Name']] = {viability: Unit.new(hsh['Viability']), live_cell_count:  Unit.new(hsh['Live Cells/mL'], 'cells')}
        end
      end
    end

    def each_well_and_parameters(&block)
      qc_data.each(&block)
    end

  end
end
