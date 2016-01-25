class AddPreExtractedPlateSubmissionTemplate < ActiveRecord::Migration
  def pre_extracted_plate_name
    'Pre-extracted plate'
  end
  def up
    ActiveRecord::Base.transaction do |t|
      SampleManifestTemplate.create!(
        :name=> pre_extracted_plate_name,
        :asset_type => 'pre_extracted_plate',
        :path => '/data/base_manifest.xls',
        :cell_map => {
          :study => [4,1],
          :supplier => [5,1],
          :number_of_plates => [6,1]
        }
       )
    end
  end

  def down
    ActiveRecord::Base.transaction do |t|
      SampleManifestTemplate.find_by_name(pre_extracted_plate_name).destroy
    end
  end
end
