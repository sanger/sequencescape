module SampleManifestExcel
  module Worksheet
    class Base
      include ActiveModel::Model

      attr_accessor :workbook, :axlsx_worksheet, :columns, :name, :ranges, :password

      def initialize(attributes = {})
        super
        create_worksheet
        protect if password.present?
      end

      # Adds row to a worksheet with particular value, style and type for each cell

      def add_row(values = [], style = nil, types = nil)
        axlsx_worksheet.add_row values, types: types || [:string] * values.length, style: style
      end

      # Adds n empty rows
      def add_rows(n)
        n.times { |_i| add_row }
      end

      # Assigns name to a worksheet depending on axlsx worksheet name. Used to assign
      # absolute references to ranges.

      def name
        @name ||= axlsx_worksheet.name
      end

      # Protects worksheet, but sizes of rows and columns can be changed

      def protect
        axlsx_worksheet.sheet_protection do |sheet_protection|
          sheet_protection.format_columns = false
          sheet_protection.format_rows = false
          sheet_protection.password = password
        end
      end

      # Adds axlsx worksheet to a workbook, to a particular place.

      def insert_axlsx_worksheet(name, index = 0)
        @axlsx_worksheet ||= workbook.insert_worksheet(index, name: name)
      end

      # Creates a worksheet, empty one in this case

      def create_worksheet
        insert_axlsx_worksheet('Base')
      end
    end
  end
end
