#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class RennameIlbIscHtpPurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Purpose.find(:all,:conditions => 'name LIKE("ISC-HTP%")').each do |purpose|
        _,suffix = */ISC-HTP(.+)/.match(purpose.name)
        say "Renaming #{purpose.name} to ISCH#{suffix}"
        purpose.update_attributes!(:name=>"ISCH#{suffix}")
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find(:all,:conditions => 'name LIKE("ISCH%")').each do |purpose|
        _,suffix = */ISCH(.+)/.match(purpose.name)
        say "Renaming #{purpose.name} to ISC-HTP#{suffix}"
        purpose.update_attributes!(:name=>"ISC-HTP#{suffix}")
      end
    end
  end
end
