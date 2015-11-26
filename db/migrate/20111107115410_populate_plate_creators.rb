#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class PopulatePlateCreators < ActiveRecord::Migration
  class PlateCreator < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      self.table_name =('plate_creator_purposes')

      belongs_to :plate_purpose, :class_name => 'PopulatePlateCreators::PlatePurpose'
      belongs_to :plate_creator, :class_name => 'PopulatePlateCreators::PlateCreator'
    end

    self.table_name =('plate_creators')

    has_many :plate_creator_purposes, :class_name => 'PopulatePlateCreators::PlateCreator::Relationship', :dependent => :destroy, :foreign_key => :plate_creator_id
    has_many :plate_purposes, :through => :plate_creator_purposes

    belongs_to :plate_purpose, :class_name => 'PopulatePlateCreators::PlatePurpose'
  end

  class PlatePurpose < ActiveRecord::Base
    class Relationship < ActiveRecord::Base
      self.table_name =('plate_purpose_relationships')
      belongs_to :parent, :class_name => 'PopulatePlateCreators::PlatePurpose'
      belongs_to :child, :class_name => 'PopulatePlateCreators::PlatePurpose'
    end

    self.table_name =('plate_purposes')
    set_inheritance_column :_type_disabled

    has_many :child_relationships, :class_name => 'PopulatePlateCreators::PlatePurpose::Relationship', :foreign_key => :parent_id, :dependent => :destroy
    has_many :child_plate_purposes, :through => :child_relationships, :source => :child
  end

  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.find_all_by_qc_display(true).each do |plate_purpose|
        PlateCreator.create!(:plate_purpose => plate_purpose, :name => plate_purpose.name).tap do |creator|
          creator.plate_purposes = plate_purpose.child_plate_purposes
        end
      end
    end
  end

  def self.down
    PlateCreator.destroy_all
  end
end
