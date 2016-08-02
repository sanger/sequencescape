#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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
