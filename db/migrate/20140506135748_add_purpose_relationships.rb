class AddPurposeRelationships < ActiveRecord::Migration
  def self.up
    Purpose::Relationship.create!(:parent=>Purpose.find_by_name('Reporter Plate'),:child=>Purpose.find_by_name('Tag PCR'),:transfer_request_type=>RequestType.transfer)
  end

  def self.down

  end
end
