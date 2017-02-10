# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
require 'benchmark'

class UpdateDilutionFactorForWdAndPd < ActiveRecord::Migration
  def self.types
    [
      {
        purpose_name: 'Working Dilution',
        value: 12.5
      },
      {
        purpose_name: 'Pico Dilution',
        value: 50.0
      }
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do |_t|
      types.each do |c|
        Purpose.find_by!(name: c[:purpose_name]).plates.find_each do |plate|
          plate.dilution_factor = c[:value]
          plate.save!
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |_t|
      types.each do |c|
        Purpose.find_by!(name: c[:purpose_name]).plates.find_each do |plate|
          plate.dilution_factor = 1.0
          plate.save!
        end
      end
    end
  end
end
