class AddXtenPlatePurposeRelationships < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_branch(["Lib PCR-XP","Lib Norm","Lib Norm 2","Lib Norm 2 Pool"])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ["Lib Norm","Lib Norm 2","Lib Norm 2 Pool"].inject("Lib PCR-XP") do |parent,child|
        Purpose.find_by_name(parent).plate_purpose_relationships.find_by_child_id(Purpose.find_by_name(child).id).destroy
      end
    end
  end
end
