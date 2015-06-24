#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ShortenExistingStripTubeNames < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      StripTube.find_each do |strip|
        old_name = strip.name
        new_name = old_name.gsub(/-[0-9]+/,'')
        strip.name = new_name
        say "Renaming #{old_name} to #{new_name}"
        strip.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      StripTube.find_each do |strip|
        old_name = strip.name
        batch_id = strip.wells.first.requests_as_atrget.first.batch.id
        new_name = "#{old_name}-#{batch_id}"
        strip.name = new_name
        say "Renaming #{old_name} to #{new_name}"
        strip.save!
      end
    end
  end
end
