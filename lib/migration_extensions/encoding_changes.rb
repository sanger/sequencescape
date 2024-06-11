# frozen_string_literal: true

# Include in an ActiveRecord::Migration to add the ability to easily migrate
# schema encodings using change_encoding
module MigrationExtensions::EncodingChanges
  # Default collation for listed character encodings
  ENCODING_COLLATIONS = {
    'latin1' => 'latin1_swedish_ci',
    'utf8mb4' => 'utf8mb4_unicode_ci',
    'utf8' => 'utf8_general_ci'
  }.freeze
  DEFAULT_TARGET_ROW_FORMAT = 'DYNAMIC'
  DEFAULT_SOURCE_ROW_FORMAT = 'COMPACT'

  #
  # Converts the table to a new character_encoding. Can be used in a reversible 'change'
  # migration
  # @note DYNAMIC row formats are the 5.7 defaults, and allow for larger indexes. This is important
  #       as otherwise it reduces the max size of an indexed varchar column from 255 to 191 when dealing
  #       with utf8mb4 characters.
  # @example migrating a table from latin1 to utf8mb4
  #  change_encoding 'study_metadata', from: 'latin1', to: 'utf8mb4'
  #
  # @param table [String] The name of the table to convert
  # @param to [String] The target character set of the converted table, or a hash of options
  # @param from [String, Hash] The current character set, or a hash of options. Used in the event of a down migration.
  # @option to [String] character_set: The target character set of the converted table
  # @option to [String] collation: The target colaltion set of the converted table. Default based on ENCODING_COLLATIONS
  # @option to [String] row_format: The row_format of the target table (DYNAMIC by default)
  # @option from [String] character_set: The current character set of the table
  # @option from [String] collation: The current colaltion set of the table. Default based on ENCODING_COLLATIONS
  # @option from [String] row_format: The current row_format of the table (COMPACT by default)
  #
  # @return [void]
  def change_encoding(table, from:, to:) # rubocop:todo Metrics/AbcSize
    from_options = from.is_a?(String) ? { character_set: from } : from
    to_options = to.is_a?(String) ? { character_set: to } : to

    reversible do |dir|
      dir.up do
        row_format = to_options.fetch(:row_format, DEFAULT_TARGET_ROW_FORMAT)
        character_set = to_options.fetch(:character_set)
        collation = to_options.fetch(:collation, ENCODING_COLLATIONS[character_set])
        alter_encoding(table, row_format, character_set, collation)
      end
      dir.down do
        row_format = from_options.fetch(:row_format, DEFAULT_SOURCE_ROW_FORMAT)
        character_set = from_options.fetch(:character_set)
        collation = from_options.fetch(:collation, ENCODING_COLLATIONS[character_set])
        alter_encoding(table, row_format, character_set, collation)
      end
    end
  end

  def alter_encoding(table, row_format, character_set, collation)
    say "Updating Encoding on #{table}"
    say "Update row format to #{row_format}", :subitem
    connection.execute("ALTER TABLE #{table} ROW_FORMAT=#{row_format}")
    say "Convert character set to #{character_set}, collation #{collation}", :subitem
    connection.execute("ALTER TABLE #{table} CONVERT TO CHARACTER SET #{character_set} COLLATE #{collation}")
  end
end
