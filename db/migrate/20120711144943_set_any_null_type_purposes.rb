class SetAnyNullTypePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Purpose.update_all('type="PlatePurpose"', 'type IS NULL')
    end
  end

  def self.down
    # Nothing to do here
  end
end
