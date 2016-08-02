#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddExternalMultiplexedLibraryCreationRequest < ActiveRecord::Migration

  class RequestType < ActiveRecord::Base
    self.table_name = 'request_types'
  end

  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(
        :asset_type=>"LibraryTube",
        :billable=>false,
        :deprecated=>false,
        :for_multiplexing=>true,
        :initial_state=>"pending",
        :key=>"external_multiplexed_library_creation",
        :morphology=>0,
        :order=>0,
        :multiples_allowed=>false,
        :name=>"External Multiplexed Library Creation",
        :no_target_asset=>false,
        :request_class_name=>"ExternalLibraryCreationRequest"
      )
    end
  end

  def self.down
    ActiveRecord::Dase.transaction do
      RequestType.find_by_key("external_multiplexed_library_creation").destroy
    end
  end
end
