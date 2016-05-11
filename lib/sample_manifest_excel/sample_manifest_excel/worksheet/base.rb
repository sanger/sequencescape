module SampleManifestExcel

  module Worksheet

    class Base

    	attr_accessor :axlsx_worksheet, :columns, :ranges, :sample_manifest, :styles, :name, :password, :type

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

      def create_worksheet
      end

    end
  end
end