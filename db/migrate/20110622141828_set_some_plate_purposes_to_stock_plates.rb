#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class SetSomePlatePurposesToStockPlates < ActiveRecord::Migration
  class PlatePurpose < ActiveRecord::Base
    self.table_name =('plate_purposes')
  end

  PLATES_THAT_CAN_BE_CONSIDERED_STOCK_PLATES = [
    'Stock plate',
    'Aliquot 1',
    'Aliquot 2',
    'Aliquot 3',
    'Aliquot 4',
    'Aliquot 5'
  ]

  def self.up
    PlatePurpose.transaction do
      PlatePurpose.update_all(
        'can_be_considered_a_stock_plate=TRUE',
        [ 'name IN (?)', PLATES_THAT_CAN_BE_CONSIDERED_STOCK_PLATES ]
      )
    end
  end

  def self.down
    # Nothing to do here as the previous migration will drop the column
  end
end
