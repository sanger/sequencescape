class AddSeperateTubeManifests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SampleManifestTemplate.all.each do |sm|
        sm.update_attributes!(:asset_type=>'plate')
      end

      each_tube_manifest do |name,path|
        SampleManifestTemplate.create!(
          :name=> name,
          :asset_type => '1dtube',
          :path => path,
          :cell_map => {:study=>[4, 1], :supplier=>[5, 1], :number_of_plates=>[6, 1]}
        )
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_tube_manifest {|name,_| SampleManifestTemplate.find_by_name(name).destroy }
      SampleManifestTemplate.all.each do |sm|
        sm.update_attributes!(:asset_type=>nil)
      end
    end
  end

  def self.each_tube_manifest
    [
      ['default tube manifest', '/data/base_tube_manifest.xls' ],
      ['full tube manifest',    '/data/full_tube_manifest.xls' ]
    ].each {|manifest| yield(*manifest)}
  end
end
