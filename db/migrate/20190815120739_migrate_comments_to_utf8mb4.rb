# frozen_string_literal: true

# Comment arenother major source of free-text human input
class MigrateCommentsToUtf8mb4 < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.connection.execute(<<~SQLQUERY
      ALTER TABLE comments CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    SQLQUERY
                                         )
  end

  def down
    ActiveRecord::Base.connection.execute(<<~SQLQUERY
      ALTER TABLE comments CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci
    SQLQUERY
                                         )
  end
end
