# frozen_string_literal: true
# This class is responsible for updating the conditional formatting for columns in the manifest.
# The formatting is applied based on the asset type, specifically targeting columns related to library assets.
#
# Example Usage:
#   conditional_updater = ConditionalFormatUpdater.new(columns: columns, asset_type: 'library')
#   conditional_updater.update_by_asset_type
# SampleManifest::Generator
class SampleManifest::ColumnConditionalFormatUpdater
  # Predefined conditional formats for required fields.
  REQUIRED_COLUMNS_CONDITIONAL_FORMATS = [
    SequencescapeExcel::ConditionalFormatting.new(
      name: 'empty_mandatory_cell',
      options: {
        'type' => :cellIs,
        'formula' => 'FALSE',
        'operator' => :equal,
        'priority' => 1
      },
      style: {
        'bg_color' => 'DC3545',
        'type' => :dxf
      }
    ),
    SequencescapeExcel::ConditionalFormatting.new(
      name: 'is_error',
      options: {
        'type' => :expression,
        'priority' => 2
      },
      style: {
        'bg_color' => 'FF0000',
        'type' => :dxf
      }
    )
  ].freeze

  # Initializes the conditional format updater with columns and asset type.
  #
  # @param columns [Array<Column>] The collection of columns to be updated.
  # @param asset_type [String] The type of the asset (e.g., 'library', 'library_plate').
  def initialize(columns:, asset_type:)
    @columns = columns
    @asset_type = asset_type
  end

  # Checks if the asset is a library asset.
  # @return [Boolean] Returns true if the asset type is either 'library' or 'library_plate'.
  def library_asset?
    %w[library library_plate].include?(@asset_type)
  end

  # Updates the conditional formatting for columns based on the asset type.
  # Currently, it applies conditional formatting for library assets only.
  # If the asset type is not library, no formatting is applied.
  #
  # @return [Array<Column>] The updated columns with conditional formatting applied.
  def update_column_formatting_by_asset_type
    if library_asset?
      update_columns_formatting(%w[library_type insert_size_from insert_size_to], REQUIRED_COLUMNS_CONDITIONAL_FORMATS)
    else
      @columns
    end
  end

  # Updates the conditional formatting for the specified columns.
  # It applies the given set of conditional formats to the matching columns.
  #
  # @param columns_to_update [Array<string>] The list of column names to update.
  # @param conditional_formats [Array<SequencescapeExcel::ConditionalFormatting>] The conditional formats to apply.
  # @return [Array<Column>] The updated columns with the new conditional formatting.
  def update_columns_formatting(columns_to_update, conditional_formats)
    columns_to_update
      .filter_map { |rc| @columns.find_by(:name, rc) }
      .each do |column|
        column.conditional_formattings.reset!
        conditional_formats.each { |format| column.conditional_formattings.add(format) }
      end
    @columns
  end
end
