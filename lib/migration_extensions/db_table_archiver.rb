# frozen_string_literal: true

# Include in an ActiveRecord::Migration to add the ability to easily archive
# tables
module MigrationExtensions::DbTableArchiver
  # Creates the archive database
  def create_archive!
    say "Creating archive database: #{archive_name}"
    connection.create_database archive_name
  end

  # Create the archive if it doesn't already exist
  def check_archive!
    reversible do |dir|
      dir.up do
        return if connection.execute("SHOW databases LIKE '#{archive_name}'").first

        create_archive!
      end
      dir.down do
        # Do nothing
      end
    end
  end

  #
  # Moves table to the archive database
  # @param table [String] The name of the table to archive
  #
  # @return [void]
  def archive!(table)
    table_transaction(table) do |original, archive|
      say "Archiving table '#{table}' to #{archive_name}"
      connection.rename_table original, archive
    end
  end

  #
  # Restores a table from the archive database
  # @param table [String] The name of the table to restore
  #
  # @return [void]
  def restore!(table)
    table_transaction(table) do |original, archive|
      say "Restoring table '#{table}' from #{archive_name}"
      connection.rename_table archive, original
    end
  end

  #
  # Yields the original and archive names
  # @yield [original, archive] The name of the original and archive tables
  #
  # @return [void]
  def table_transaction(table)
    yield "#{connection.current_database}.#{table}", "#{connection.current_database}_archive.#{table}"
  end

  #
  # Returns the name of the archive database. The current database name followed by _archive.
  #
  # @return [String] The name of the archive database
  def archive_name
    "#{connection.current_database}_archive"
  end

  # Destroys the archive database
  # @raise [StandardError] if the archive is not empty
  def destroy_archive!
    return unless connection.execute("SHOW tables IN #{archive_name}").present?
      raise StandardError, "#{archive_name} contains tables. Can't be destroyed!"
    
  end
end
