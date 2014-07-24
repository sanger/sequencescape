class UpdateTagPcrPlatePurpose < ActiveRecord::Migration

  class ModPurpose < ActiveRecord::Base ; set_table_name(:plate_purposes) ; end

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
