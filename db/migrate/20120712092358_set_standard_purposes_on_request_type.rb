#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetStandardPurposesOnRequestType < ActiveRecord::Migration
  TARGET_ASSET_TYPES_TO_PURPOSES = {
    'MultiplexedLibraryTube' => 'Standard MX',
    'LibraryTube'            => 'Standard library'
  }

  class Tube
    class Purpose < ActiveRecord::Base
      self.table_name =('plate_purposes')
      set_inheritance_column
    end
  end

  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')
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
