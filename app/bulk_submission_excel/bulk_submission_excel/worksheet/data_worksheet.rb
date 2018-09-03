# frozen_string_literal: true

module BulkSubmissionExcel
  module Worksheet
    ##
    # DataWorksheet creates a data worksheet to be filled in by a client.
    class DataWorksheet < SampleManifestExcel::Worksheet::Base
      attr_accessor :assets, :defaults

      include SampleManifestExcel::Helpers::Worksheet

      self.worksheet_name = 'Submission Form'

      def initialize(attributes = {})
        super
        create_styles
        add_title_and_description
        add_columns
        freeze_panes
      end

      def first_row
        3
      end

      #
      # Returns a hash of defaults where a value has been provided
      #
      # @return [Hash] Defaults where keys are present?
      def present_defaults
        defaults.select { |_k, v| v.present? }
      end

      # Adds title and description (study abbreviation, supplier name, number of assets sent)
      # to a worksheet.

      def add_title_and_description
        add_row ['Bulk Submissions Form']
      end

      # Using axlsx worksheet creates data worksheet with title, description, all required columns, values,
      # data validations, conditional formattings, freezes panes at required place.

      # Adds columns with all required data to a worksheet

      def add_columns
        columns.update(first_row, last_row, ranges, axlsx_worksheet)
        add_headers
        assets.each do |asset|
          detail = build_details(asset)
          create_row(detail)
        end
      end

      # Extract the details for the given asset
      def build_details(asset)
        {
          project_name: asset.projects.one? ? asset.projects.first.name : '',
          study_name: asset.studies.one? ? asset.studies.first.name : '',
          barcode: asset.labware_human_barcode,
          plate_well: asset.respond_to?(:map_description) ? asset.map_description : nil
        }.reverse_merge(present_defaults)
      end

      # Creates row filled in with required column values, also unlocks (adds unlock style)
      # the cells that should be filled in by clients

      def create_row(detail)
        axlsx_worksheet.add_row do |row|
          columns.each do |column|
            if column.unlocked?
              row.add_cell column.attribute_value(detail), type: column.type, style: styles[:unlocked].reference
            else
              row.add_cell column.attribute_value(detail), type: column.type
            end
          end
        end
      end

      # Freezes panes vertically after particular column (sanger_sample_id by default)
      # and horizontally after headings

      def freeze_panes(name = :sanger_sample_id)
        axlsx_worksheet.sheet_view.pane do |pane|
          pane.state = :frozen
          pane.y_split = first_row - 1
          pane.x_split = freeze_after_column(name)
          pane.active_pane = :bottom_right
        end
      end

      # Finds the column after which the panes should be frozen. If the column was not found
      # freezes the panes after column 0 (basically not frozen vertically)

      def freeze_after_column(name)
        columns.find_by(:name, name) ? columns.find_by(:name, name).number : 0
      end

      # The row where the table with data end
      def last_row
        @last_row ||= assets.count + first_row - 1
      end
    end
  end
end
