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
