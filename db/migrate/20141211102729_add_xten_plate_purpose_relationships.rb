class AddXtenPlatePurposeRelationships < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose::Relationship.create!(
        :parent => Purpose.find_by_name!("Lib Norm"),
        :child => Purpose.find_by_name!("Lib Norm 2"),
        :transfer_request_type => RequestType.transfer
        )
      PlatePurpose::Relationship.create!(
        :parent => Purpose.find_by_name!("Lib Norm 2"),
        :child => Purpose.find_by_name!("Lib Norm 2 Pool"),
        :transfer_request_type => RequestType.transfer
        )
      PlatePurpose::Relationship.create!(
        :parent => Purpose.find_by_name!("Lib PCR-XP"),
        :child => Purpose.find_by_name!("Lib Norm"),
        :transfer_request_type => RequestType.transfer
        )

    end

  end

  def self.down
  end
end
