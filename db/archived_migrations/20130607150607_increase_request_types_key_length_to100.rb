#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IncreaseRequestTypesKeyLengthTo100 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      change_column 'request_types', 'key', :string, :limit => 100
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      change_column 'request_types', 'key', :string, :limit => 50
    end
  end
end
