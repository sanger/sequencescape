#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddLibraryManifestLayout < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
        SampleManifestTemplate.create!(
          :name=> 'Simple multiplexed library manifest',
          :asset_type => 'multiplexed_library',
          :path => '/data/base_mx_library_manifest.xls',
          :cell_map => {:study=>[4, 1], :supplier=>[5, 1], :number_of_plates=>[6, 1]}
        )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SampleManifestTemplate.find_bty_name('Simple multiplexed library manifest').destroy
    end
  end
end
