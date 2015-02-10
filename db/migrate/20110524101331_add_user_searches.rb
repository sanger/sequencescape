#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddUserSearches < ActiveRecord::Migration
  def self.up
    {
 'Find user by login' => Search::FindUserByLogin,
     'Find user by swipecard code' => Search::FindUserBySwipecardCode
    }.each do |name, model|
      model.create!(:name => name) unless model.find_by_name(name)
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
