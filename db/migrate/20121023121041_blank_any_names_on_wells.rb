class BlankAnyNamesOnWells < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Well.find_each(:conditions => 'name IS NOT NULL AND LENGTH(name) > 0') do |well|
        well.update_attributes!(:name => nil)
      end
    end
  end

  def self.down
    # Nothing to do
  end
end
