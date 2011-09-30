class ChangePulldownStockPlatePurpose < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    set_table_name('plate_purposes')

    def self.change_implementation(to)
      PlatePurpose.update_all(
        "type=#{ to.nil? ? 'NULL' : to.inspect }",
        [ 'name IN (?)', [ 'WGS stock DNA', 'SC stock DNA', 'ISC stock DNA' ] ]
      )
    end
  end

  def self.up
    PlatePurpose.change_implementation('Pulldown::StockPlatePurpose')
  end

  def self.down
    PlatePurpose.change_implementation(nil)
  end
end
