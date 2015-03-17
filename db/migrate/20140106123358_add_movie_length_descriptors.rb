#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddMovieLengthDescriptors < ActiveRecord::Migration
  def self.up
    Task.find_by_name('Movie Lengths').descriptors.create!(
      :name => 'Movie length',
      :kind => 'Selection',
      :selection => [30, 60, 90, 120, 180]
    )
  end

  def self.down
    Task.find_by_name('Movie Lengths').descriptors.clear
  end
end
