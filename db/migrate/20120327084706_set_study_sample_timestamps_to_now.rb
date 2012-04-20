class SetStudySampleTimestampsToNow < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      StudySample.update_all('created_at=now(), updated_at=now()')
    end
  end

  def self.down
    # Do nothing, not relevant
  end
end
