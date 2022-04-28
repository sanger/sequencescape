# frozen_string_literal: true

# We're about to make some major changes to lab events, so lets back it up for
# disaster recovery reasons.
# CAUTION: This table contains the data only, not the indexes.
class BackUpLabEvents < ActiveRecord::Migration[5.2]
  def up
    ActiveRecord::Base.connection.execute(<<~SQL.squish)
      CREATE TABLE bkp_lab_events AS SELECT * FROM lab_events
    SQL
  end

  def down
    drop_table :_bkp_lab_events
  end
end
