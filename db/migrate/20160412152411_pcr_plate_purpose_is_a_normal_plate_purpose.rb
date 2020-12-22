# We are consolidating plate purpose classes as we push custom behaviour outwards
class PcrPlatePurposeIsANormalPlatePurpose < ActiveRecord::Migration
  class Purpose < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = 'plate_purposes'
  end

  def up
    ActiveRecord::Base.transaction do
      Purpose.where(name: 'ILB_STD_PCR').update_all(type: 'PlatePurpose')
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Purpose.where(name: 'ILB_STD_PCR').update_all(type: 'IlluminaB::PcrPlatePurpose')
    end
  end
end
