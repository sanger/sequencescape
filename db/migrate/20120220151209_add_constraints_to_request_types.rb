class AddConstraintsToRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      change_column :request_types, :name, :string, :unique => true, :null => false
      change_column :request_types, :initial_state, :string, :default => 'pending', :null => false
    end
  end

  def self.down
  end
end
