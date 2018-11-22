class LibPcrPlatesNoLongerNeedSpecialBehaviour < ActiveRecord::Migration
  class PlatePurpose < ApplicationRecord
    self.table_name = 'plate_purposes'
    self.inheritance_column = nil
  end

  def up
    ActiveRecord::Base.transaction do
      PlatePurpose.where(name: 'Lib PCR').each do |purpose|
        purpose.type = 'PlatePurpose'
        purpose.save!
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      PlatePurpose.where(name: 'Lib PCR').each do |purpose|
        purpose.type = 'IlluminaHtp::LibPcrPlatePurpose'
        purpose.save!
      end
    end
  end
end
