# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class PopulateValidOptionsForPlateCreators < ActiveRecord::Migration
  def self.population_data
  [
    ["Working dilution", [12.5, 20.0, 15.0, 50.0]],
    ["Pico dilution", [4.0]]
  ]
  end
  def self.up
    ActiveRecord::Base.transaction do
      self.population_data.each do |name, values|
        c = Plate::Creator.find_by_name!(name)
        c.update_attributes!(:valid_options => {
            :valid_dilution_factors => values
        })
      end
      Plate::Creator.all.each do |c|
        if c.valid_options.nil?
          # Any other valid option will be set to 1
          c.update_attributes!(:valid_options => {
              :valid_dilution_factors => [1.0]
          })
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      self.population_data.each do |name, values|
        c = Plate::Creator.find_by_name!(name)
        c.update_attributes!(:valid_options => nil)
      end
    end
  end
end
