class AddNewIlluminaAPurposes < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      Pulldown::PlatePurposes.create_purposes(branch)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      branch.shift
      branch.each {|name| Purpose.find_by_name(name).destroy }
    end
  end

  def self.branch
    [
      'Lib PCR-XP',
      'ISC-HTP lib pool',
      'ISC-HTP hyb',
      'ISC-HTP cap lib',
      'ISC-HTP cap lib PCR',
      'ISC-HTP cap lib PCR-XP',
      'ISC-HTP cap lib pool'
    ]
  end
end
