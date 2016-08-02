#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddDefaultToMovieLength < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Descriptor.find_by_name('Movie length').tap do |ml|
        ml.selection = [30, 60, 90, 120, 180, 210, 240]
        ml.value = 180
      end.save!
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Descriptor.find_by_name('Movie length').tap do |ml|
        ml.selection = [30, 60, 90, 120, 180]
        ml.value = nil
      end.save!
    end
  end
end
