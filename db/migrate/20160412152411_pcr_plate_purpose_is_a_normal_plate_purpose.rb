#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class PcrPlatePurposeIsANormalPlatePurpose < ActiveRecord::Migration

  class Purpose < ActiveRecord::Base
    self.table_name='plate_purposes'
  end

  def up
    ActiveRecord::Base.transaction do
      Purpose.where(name:'ILB_STD_PCR').update_all(type:'PlatePurpose')
    end
  end

  def down
    ActiveRecord::Base.transaction do
      Purpose.where(name:'ILB_STD_PCR').update_all(type:'IlluminaB::PcrPlatePurpose')
    end
  end
end
