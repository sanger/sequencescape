#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class UpdateCherrypickRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('Cherrypick').update_attributes!(:request_class_name => 'CherrypickForPulldownRequest')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_by_name('Cherrypick').update_attributes!(:request_class_name => 'Request')
    end
  end
end
