# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class LibPcrPlatesNoLongerNeedSpecialBehaviour < ActiveRecord::Migration

  class PlatePurpose < ActiveRecord::Base
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
