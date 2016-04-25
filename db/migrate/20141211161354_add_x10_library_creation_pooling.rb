#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddX10LibraryCreationPooling < ActiveRecord::Migration
  def self.transfer_layout_96
    layout = {}
    ('A'..'H').each do |row|
      (1..12).each do |column|
        layout["#{row}#{column}"]="#{row}1"
      end
    end
    layout
  end

  def self.up
    ActiveRecord::Base.transaction do
      TransferTemplate.create!(
        :name => "Pooling rows to first column",
        :transfer_class_name => "Transfer::BetweenPlates",
        :transfers => self.transfer_layout_96
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TransferTemplate.find_by_name!("Pooling rows to first column").destroy
    end
  end
end
