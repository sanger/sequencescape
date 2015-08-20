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
