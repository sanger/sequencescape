#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddManifestRnaChip < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |t|
      # Cell position for storing study, supplier and n.plates inside the .xls file
      map = {
          :study => [4,1],
          :supplier => [5,1],
          :number_of_plates => [6,1]
      }

      if SampleManifestTemplate.find_by_name("relevant RNA/ChIP").nil?
        SampleManifestTemplate.create!(
          :name => "relevant RNA/ChIP",
          :path => "/data/relevant_rnachip_plate_manifest.xls",
          :cell_map => map,
          :asset_type => '1dtube'
        )
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |t|
      SampleManifestTemplate.find_by_name("relevant RNA/ChIP").destroy
    end
  end
end
