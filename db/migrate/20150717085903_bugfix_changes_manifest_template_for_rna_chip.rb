class BugfixChangesManifestTemplateForRnaChip < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do |t|
      map = {
          :study => [4,1],
          :supplier => [5,1],
          :number_of_plates => [6,1]
      }

      SampleManifestTemplate.find_by_name("relevant RNA/ChIP").update_attributes!({
        :asset_type => 'plate',
      })

      SampleManifestTemplate.create!({
        :name => "relevant RNA/ChIP tube",
        :path => "/data/relevant_rnachip_tube_manifest.xls",
        :cell_map => map,
        :asset_type => '1dtube'
      })
    end
  end

  def self.down
    ActiveRecord::Base.transaction do |t|
      SampleManifestTemplate.find_by_name("relevant RNA/ChIP").destroy
      SampleManifestTemplate.find_by_name("relevant RNA/ChIP tube").destroy
    end
  end
end
