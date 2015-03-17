#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class WholePlateToTubeTransferTemplate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => 'Whole plate to tube',
        :transfer_class_name => 'Transfer::FromPlateToTube',
        :transfers => all_wells
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name('Whole plate to tube').destroy
    end
  end

  def self.all_wells
    ('A'..'H').map {|l| (1..12).map {|n| "#{l}#{n}" }}.flatten
  end
end
