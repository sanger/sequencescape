class AddConsentWithdrawnFlagToSample < ActiveRecord::Migration
  def self.up
    add_column :samples, :consent_withdrawn, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :samples, :consent_withdrawn
  end
end
