module SampleManifestExcel

  module Worksheet

    class Base

    	attr_accessor :workbook, :axlsx_worksheet, :columns, :ranges, :sample_manifest, :styles, :name, :password, :type

    	def initialize(attributes = {})
    	  attributes.each { |name, value| send("#{name}=", value) }
        create_worksheet
        protect if password
    	end

    	def add_row(values = [], style = nil, types = nil)
  			axlsx_worksheet.add_row values, types: types || [:string]*values.length, style: style
    	end

    	def add_rows(n)
        n.times { |i| add_row }
      end

      def name
        @name ||= axlsx_worksheet.name
      end

      def protect
      	axlsx_worksheet.sheet_protection.format_columns = false
        axlsx_worksheet.sheet_protection.format_rows = false
      	axlsx_worksheet.sheet_protection.password = password
      end

      def insert_axlsx_worksheet(index=0, name)
        @axlsx_worksheet ||= workbook.insert_worksheet(index, name: name)
      end

      def create_worksheet
        insert_axlsx_worksheet("Base")
      end

    end
  end
end