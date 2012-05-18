class HideLibraryTypeInInbox < ActiveRecord::Migration
  def self.up
    RequestInformationType.find_by_key('library_type').update_attributes(:hide_in_inbox => true)
  end

  def self.down
    RequestInformationType.find_by_key('library_type').update_attributes(:hide_in_inbox => false)
  end
end
