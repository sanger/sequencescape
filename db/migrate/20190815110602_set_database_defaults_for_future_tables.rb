# frozen_string_literal: true

# In order to ensure sensible defaults in future, we update the database defaults.
class SetDatabaseDefaultsForFutureTables < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute(<<~SQLQUERY)
      ALTER DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    SQLQUERY
  end

  def down
    ActiveRecord::Base.connection.execute(<<~SQLQUERY)
      ALTER DATABASE CHARACTER SET latin1 COLLATE latin1_swedish_ci
    SQLQUERY
  end
end
