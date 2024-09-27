# frozen_string_literal: true

module SequencescapeExcel
  module Worksheet
    ##
    # Base class for worksheets
    class Base
      include ActiveModel::Model

      class_attribute :worksheet_name
      self.worksheet_name = 'DNA Collections Form'

      attr_accessor :workbook, :axlsx_worksheet, :columns, :ranges, :password
      attr_writer :name

      def initialize(attributes = {})
        super
        create_worksheet
        protect if password.present?
      end

      # Adds row to a worksheet with particular value, style and type for each cell

      def add_row(values = [], style = nil, types = nil)
        axlsx_worksheet.add_row values, types: types || ([:string] * values.length), style: style
      end

      # Adds n empty rows
      def add_rows(num_rows)
        num_rows.times { |_i| add_row }
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
        @axlsx_worksheet ||= workbook.insert_worksheet(index, name:) # rubocop:disable Naming/MemoizedInstanceVariableName
      end

      # Creates a worksheet, empty one in this case

      def create_worksheet
        insert_axlsx_worksheet(worksheet_name)
      end
    end
  end
end
