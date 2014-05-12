module DbTableArchiver

  def self.create_archive!
    puts "Creating archive database: #{archive_name}"
    ActiveRecord::Base.connection.create_database archive_name
  end

  def self.archive!(table)
    table_transaction(table) do |original,archive|
      puts "Archiving table '#{table}' to #{archive_name}"
      ActiveRecord::Base.connection.rename_table original, archive
    end
  end

  def self.restore!(table)
    table_transaction(table) do |original,archive|
      puts "Restoring table '#{table}' from #{archive_name}"
      ActiveRecord::Base.connection.rename_table archive, original
    end
  end

  def self.table_transaction(table)
    yield "#{ActiveRecord::Base.connection.current_database}.#{table}", "#{ActiveRecord::Base.connection.current_database}_archive.#{table}"
  end

  def self.archive_name
    "#{ActiveRecord::Base.connection.current_database}_archive"
  end


  def self.destroy_archive!
    raise StandardError, "#{archive_name} contains tables. Can't be destroyed!" if ActiveRecord::Base.connection.execute("SHOW tables IN #{archive_name}").present?
  end

end
