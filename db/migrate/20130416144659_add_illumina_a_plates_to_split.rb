class AddIlluminaAPlatesToSplit < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_branch(['Lib PCR-XP','ISC lib pool'])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Lib PCR-XP').child_purposes.delete(Purpose.find_by_name('ISC lib pool'))
    end
  end
end
