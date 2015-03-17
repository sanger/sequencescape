#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class CreateFlippedTemplate < ActiveRecord::Migration
  def self.up
    TransferTemplate.create!(
      :name => 'Flip Plate',
      :transfer_class_name => 'Transfer::BetweenPlates',
      :transfers => template
    )
  end

  def self.down
    TransferTemplate.find_by_name('Flip Plate').destroy
  end

  def self.template
    wells = (1..12).map {|c| ('A'..'H').map {|r| "#{r}#{c}"}}.flatten
    Hash[wells.zip(wells.reverse)]
  end
end
