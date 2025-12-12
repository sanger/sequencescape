# frozen_string_literal: true
require 'database_cleaner-active_record'

module DatabaseCleaner
  module ActiveRecord
    # SeededDeletion is a strategy that deletes all records from tables except those that existed
    # before it was instantiated
    # This is useful for tests that need the seeded data to be present.
    class SeededDeletion < Deletion
      VERSION = '1.0'

      def clean
        connection.transaction(requires_new: true) do
          super
        end
      end

      def start
        Rails.logger.info 'SeededDeletion strategy start' if defined?(Rails) && Rails.logger
        self.class.table_max_id_cache = table_max_id_hash
      end

      def self.table_max_id_cache
        @table_max_id_cache ||= {}
      end

      # Memoize the maximum ID for each class table with non-zero number of rows
      def self.table_max_id_cache=(table_id_hash)
        @table_max_id_cache ||= table_id_hash
      end

      delegate :table_max_id_cache, to: :class

      private

      def table_max_id_hash # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        h = {}
        tables_to_clean(connection).each do |table_name|
          # Check if the table has an id column using SQL
          column_exists_query = "SELECT EXISTS (
              SELECT 1
              FROM information_schema.columns
              WHERE table_name = #{connection.quote(table_name)}
              AND column_name = 'id'
            )"

          has_id_column = connection.select_value(column_exists_query)

          if has_id_column
            # Get the maximum id using SQL
            max_id = connection.select_value("SELECT MAX(id) FROM #{connection.quote_table_name(table_name)}")

            # store the table and max id if there is non-zero number of rows
            h[table_name] = max_id.to_i if max_id.to_i.positive?
          end
        rescue StandardError => e
          # Skip tables that don't exist or have other issues
          puts "Warning: Could not cache max ID for table #{table_name}: #{e.message}"
        end
        h
      end

      # Override the delete_table to delete records with IDs greater than the cached max ID (new rows)
      def delete_table(connection, table_name)
        if table_max_id_cache.key?(table_name)
          # For seedable tables, only delete records with IDs greater than the cached max ID
          max_id = table_max_id_cache[table_name]
          if max_id.is_a?(Numeric) && max_id.positive?
            connection.execute("DELETE FROM #{connection.quote_table_name(table_name)} WHERE id > #{connection.quote(max_id)}") # rubocop:disable Layout/LineLength
          end
        else
          # For all other tables, use the standard deletion from the parent class
          super
        end
      end
    end
  end
end
