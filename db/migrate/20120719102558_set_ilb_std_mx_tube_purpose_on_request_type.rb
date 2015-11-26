#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class SetIlbStdMxTubePurposeOnRequestType < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')
    belongs_to :target_purpose, :class_name => 'SetIlbStdMxTubePurposeOnRequestType::IlluminaB::MxTubePurpose'
  end

  module IlluminaB
    class MxTubePurpose < ActiveRecord::Base
      self.table_name =('plate_purposes')
      set_inheritance_column
    end
  end

  def self.up
    change do |request_type, tube_purpose|
      request_type.update_attributes!(:target_asset_type => nil, :target_purpose => tube_purpose)
    end
  end

  def self.down
    change do |request_type, tube_purpose|
      request_type.update_attributes!(:target_asset_type => "MultiplexedLibraryTube", :target_purpose => nil)
    end
  end

  def self.change(&block)
    ActiveRecord::Base.transaction do
      request_type = RequestType.find_by_key('illumina_b_std') or raise "Cannot find Illumina B request type"
      tube_purpose = IlluminaB::MxTubePurpose.find_by_name('ILB_STD_MX') or raise "Cannot find Illumina B MX tube purpose"
      yield(request_type, tube_purpose)
    end
  end
end
