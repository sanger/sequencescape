class SetStandardPurposesOnRequestType < ActiveRecord::Migration
  TARGET_ASSET_TYPES_TO_PURPOSES = {
    'MultiplexedLibraryTube' => 'Standard MX',
    'LibraryTube'            => 'Standard library'
  }

  class Tube
    class Purpose < ActiveRecord::Base
      set_table_name('plate_purposes')
      set_inheritance_column(nil)
    end
  end

  class RequestType < ActiveRecord::Base
    set_table_name('request_types')
    belongs_to :target_purpose, :class_name => 'SetStandardPurposesOnRequestType::Tube::Purpose'
  end

  def self.up
    ActiveRecord::Base.transaction do
      TARGET_ASSET_TYPES_TO_PURPOSES.each do |target_type, purpose_name|
        purpose = Tube::Purpose.find_by_name(purpose_name) or raise "Cannot find purpose #{purpose_name.inspect}"
        RequestType.all(:conditions => { :target_asset_type => target_type }).each do |type|
          type.update_attributes!(:target_purpose => purpose, :target_asset_type => nil)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      TARGET_ASSET_TYPES_TO_PURPOSES.each do |target_type, purpose_name|
        purpose = Tube::Purpose.find_by_name(purpose_name) or raise "Cannot find purpose #{purpose_name.inspect}"
        RequestType.all(:conditions => { :target_purpose_id => purpose.id }).each do |type|
          type.update_attributes!(:target_purpose => nil, :target_asset_type => target_type)
        end
      end
    end
  end
end
