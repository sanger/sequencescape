class EthicallyApprovedShouldBeNullByDefault < ActiveRecord::Migration
  def self.up
    change_column_default(:studies, :ethically_approved, nil)
  end

  def self.down
    change_column :studies, :ethically_approved, :default => false
  end
end
