# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class EnsureQcablePurposesHaveSensibleStartStates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_purpose(:to)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_purpose(:from)
    end
  end

  def self.each_purpose(target)
    [
      {:purpose => 'Tag Plate', :from =>'pending', :to=>'created'},
      {:purpose => 'Reporter Plate', :from =>'pending', :to=>'created'}
    ].each do |change|
      Purpose.find_by_name!(change[:purpose]).update_attributes!(:default_state=>change[target])
    end
  end
end
