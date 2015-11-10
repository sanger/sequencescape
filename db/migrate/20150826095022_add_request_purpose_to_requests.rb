#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddRequestPurposeToRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_each do |rt|
        say "Updating #{rt.name} requests"
        rt.requests.update_all(:request_purpose_id=>rt.request_purpose.id)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Request.update_all(:request_purpose_id=>nil)
    end
  end
end
