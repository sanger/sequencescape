class MakePulldownStockPlateDefaultToPassed < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')
  end

  def self.up
    PlatePurpose.update_all(
      'default_state="passed"',
      [ 'name IN (?)', [ 'WGS stock plate', 'SC stock plate', 'ISC stock plate' ] ]
    )
  end

  def self.down
    # Do not need to do anything here
  end
end
