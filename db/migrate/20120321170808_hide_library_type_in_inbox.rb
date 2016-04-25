#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class HideLibraryTypeInInbox < ActiveRecord::Migration
  def self.up
    RequestInformationType.find_by_key('library_type').update_attributes(:hide_in_inbox => true)
  end

  def self.down
    RequestInformationType.find_by_key('library_type').update_attributes(:hide_in_inbox => false)
  end
end
