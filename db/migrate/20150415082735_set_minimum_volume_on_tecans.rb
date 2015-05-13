#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class SetMinimumVolumeOnTecans < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Robot.find(:all,:conditions=>'name LIKE("Tecan%")').each do |rb|
        rb.update_attributes!(:minimum_volume=>2)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Robot.find(:all,:conditions=>'name LIKE("Tecan%")').each do |rb|
        rb.update_attributes!(:minimum_volume=>nil)
      end
    end
  end
end
