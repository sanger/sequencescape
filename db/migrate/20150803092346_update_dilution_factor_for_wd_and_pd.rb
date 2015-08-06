require "benchmark"

class UpdateDilutionFactorForWdAndPd < ActiveRecord::Migration
  def self.types
    [
      {
        :purpose_name => "Working Dilution",
        :value => 12.5
      },
      {
        :purpose_name => "Pico Dilution",
        :value => 50
      }
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do |t|
      self.types.each do |c|
        Purpose.find_by_name!(c[:purpose_name]).plates.find_each do |plate|
          plate.dilution_factor = c[:value]
          plate.save!
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |t|
      self.types.each do |c|
        Purpose.find_by_name!(c[:purpose_name]).plates.find_each do |plate|
          plate.dilution_factor = 1
          plate.save!
        end
      end
    end
  end
end
