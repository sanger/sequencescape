module SampleManifestExcel

  module Worksheet

    class Base

      include HashAttributes

      set_attributes :workbook, :axlsx_worksheet, :columns, :ranges, :sample_manifest, :name, :password, :type

      #Worksheet constructor takes different arguments depending of a type of worksheet
      #(data or ranges), creates worksheet and protects it if password is provided
      #
      #For data worksheet the following argumens are required:
      #- workbook (axlsx workbook, to insert an axlsx worksheet there)
      #- column list object (consists of columns to be placed on a worksheet)
      #- sample manifest object (from ss, used to insert values to columns that have attributes)
      #- styles (a hash with styles names as keys and style objects as values, used to apply
      #  styles to worksheet (borders, colours for conditional formatting, lock/unlock))
#  QUESTION: styles are not used in downloads and ranges worksheet.
#  Should we create them in DataWorksheet(not in Download)? (to create styles workbook and a hash with styles details are required)
      #- range list object (consists of ranges with absolute references(already placed on a
      #  ranges worksheet), to be used in data validations and conditional formatting)
      #- download type ('Plates' or 'Tubes'), used in DNA Collections Form description
      #- password, if worksheet needs to be locked (a string)
      #
      #For ranges worksheet the following arguments are required:
      #- workbook (axlsx workbook, to insert an axlsx worksheet there)
      #- range list object (consists of ranges to be placed on a worksheet)
      #- password, if worksheet needs to be locked (a string)
      #

    	def initialize(attributes = {})
        create_attributes(attributes)
        create_worksheet
        protect if password.present?
    	end

      #Adds row to a worksheet with particular value, style and type for each cell

    	def add_row(values = [], style = nil, types = nil)
  			axlsx_worksheet.add_row values, types: types || [:string]*values.length, style: style
    	end

      #Adds n empty rows

    	def add_rows(n)
        n.times { |i| add_row }
      end

      #Assigns name to a worksheet depending on axlsx worksheet name. Used to assign
      #absolute references to ranges.

      def name
        @name ||= axlsx_worksheet.name
      end

      #Protects worksheet, but sizes of rows and columns can be changed

      def protect
        axlsx_worksheet.sheet_protection do |sheet_protection|
          sheet_protection.format_columns = false
          sheet_protection.format_rows = false
          sheet_protection.password = password
        end
      end

      #Adds axlsx worksheet to a workbook, to a particular place.

      def insert_axlsx_worksheet(index=0, name)
        @axlsx_worksheet ||= workbook.insert_worksheet(index, name: name)
      end

      #Creates a worksheet, empty one in this case

      def create_worksheet
        insert_axlsx_worksheet("Base")
      end

    end
  end
end