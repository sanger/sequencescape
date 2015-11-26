#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class AssetRackCreation < AssetCreation
  include_plate_named_scope :parent

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  belongs_to :parent, :class_name => 'Asset'

  scope :include_child, -> { includes(:child) }

  def record_creation_of_children
    parent.events.create_plate!(child_purpose, child, user)
  end
  private :record_creation_of_children

  module Children

    def self.included(base)
      base.class_eval %Q{

        belongs_to :child, :class_name => 'AssetRack'

        validates_unassigned(:child)
      }
    end

    def target_for_ownership
      child
    end
    private :target_for_ownership

    def children
      [self.child]
    end
    private :children

    def create_children!
      self.child = child_purpose.create!(:location=>parent.location,:source=>parent.source_plate)
    end
    private :create_children!

  end
  include Children

end
