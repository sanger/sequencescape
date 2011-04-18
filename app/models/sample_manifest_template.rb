class SampleManifestTemplate < ActiveRecord::Base
  serialize :default_values, Hash
  serialize :cell_map, Hash

  def set_value(worksheet, cell_name, value)
    row_col = cell_map[cell_name]
    return nil unless row_col
    row, col = row_col
    worksheet.row(row)[col] = value
    return value
  end

  def self.populate()
    transaction do 
      base_template = SampleManifestTemplate.create!(:name => "default layout",
                                                      :path => "/data/base_manifest.xls",
                                                      :cell_map => {
        :study => [4,1],
        :supplier => [5,1],
        :number_of_plates => [6,1]
      })

      unless RAILS_ENV == "production"
        base2_template = SampleManifestTemplate.create!(:name => "test layout",
                                                        :path => "/data/base2_manifest.xls",
                                                        :cell_map => {
        :study => [3,1],
        :supplier => [9,0],
        :number_of_plates => [6,1]
      },
                                                       :default_values => {
        "GENDER" => "Male"
      })
      end
    end
  end

end
