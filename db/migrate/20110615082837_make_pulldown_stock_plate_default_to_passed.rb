class MakePulldownStockPlateDefaultToPassed < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
  end

  def self.up
    PlatePurpose.find_by_name('Pulldown stock plate').update_attributes!(:default_state => 'passed')
  end

  def self.down
    # Do not need to do anything here
  end
end
