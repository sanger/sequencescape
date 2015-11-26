#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class FluidigmFile

  module Finder

    class Directory
      def initialize(barcode)
        @barcode = barcode
      end
      def empty?
        !File.exists?("#{configatron.fluidigm_data.directory}/#{@barcode}/#{@barcode}.csv")
      end
      def content
        file_content = nil
        File.open("#{configatron.fluidigm_data.directory}/#{@barcode}/#{@barcode}.csv") do |file|
          file_content = file.read
        end
        file_content
      end
    end

    class Irods
      def initialize(barcode)
        @data = IrodsReader::DataObj.find('seq','dcterms:audience'=>configatron.irods_audience, :fluidigm_plate=>barcode)
      end

      def empty?
        @data.empty?
      end

      def content(index=nil)
        raise StandardError, "Multiple files found" if data.size > 1 && index.nil?
        @data[index||0].retrive
      end
    end

    def self.default
      {
        'irods' => Irods,
        'directory' => Directory
      }.fetch(configatron.fluidigm_data.source)
    end

    def self.find(barcode)
      default.new(barcode)
    end

  end

  class InvalidFile < StandardError; end

  class Assay

    attr_reader :name, :result

    @@valid_markers = ['XX','XY','YY']
    @@gender_map    = {'XX' => 'F', 'YY' => 'F', 'XY' => 'M'}

    def initialize(name,result)
      @name   = name
      @result = result
    end

    def gender_marker?
      /^GS/===name
    end

    def gender
      @@gender_map[result]||'Unknown'
    end

    def pass?
      @@valid_markers.include?(result)
    end
  end

  class FluidigmWell

    attr_reader :description

    def initialize(description)
      @description = description
    end

    def gender_markers
      marker_array.select {|m| m.gender_marker?}.map(&:gender)
    end

    def add_assay(assay,marker)
      marker_array << Assay.new(assay,marker)
    end

    def count
      marker_array.select {|m| m.pass? }.count
    end

    private

    def marker_array
      @gender_markers ||= []
    end

  end

  def initialize(file_contents)
    @csv = CSV.parse(file_contents)
    build_wells
    self
  end

  def each_well
    @wells.each {|_,w| yield(w)}
  end

  def for_plate?(test_plate)
    plate_barcode == test_plate
  end

  def plate_barcode
    @csv[0][2]
  end

  def well_at(description)
    @wells ||= Hash.new {|hash,desc| hash[desc] = FluidigmWell.new(desc) }
    @wells[description]
  end

  def well_locations
    @wells.keys
  end

  private
  def header_start_index
    @header_start_index ||= (0..@csv.size).detect {|i| @csv[i][0]=='Experiment Information'} || raise(InvalidFile,'Could not find header')
  end

  def data_start_index
    header_start_index+3
  end

  def headers
    @headers ||= @csv[header_start_index].zip(@csv[header_start_index+1]).zip(@csv[header_start_index+2]).map {|h| h.join(' ')}
  end

  def column(head)
    headers.index(head)
  end

  def build_wells
    (data_start_index...@csv.size).each do |row_index|
      row = @csv[row_index]
      next if row[column('Experiment Information Sample Name')] == 'Water'
      well = well_at(row[column('Experiment Information Chamber ID')].split('-').first)
      well.add_assay(row[column('Experiment Information SNP Assay and Allele Names Assay')],row[column('Results Call Information Final')])
    end
  end

end
