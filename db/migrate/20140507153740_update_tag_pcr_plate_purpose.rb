#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateTagPcrPlatePurpose < ActiveRecord::Migration

  class ModPurpose < ActiveRecord::Base ; self.table_name =(:plate_purposes) ; end

  def self.up
    ActiveRecord::Base.transaction do
      execute("UPDATE plate_purposes
        SET type = 'QcableLibraryPlatePurpose'
        WHERE name = 'Tag PCR';")
      Purpose.find_by_name('Tag PCR').touch
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      execute("UPDATE plate_purposes
        SET type = 'PlatePurpose'
        WHERE name = 'Tag PCR';")
      Purpose.find_by_name('Tag PCR').touch
    end
  end
end
