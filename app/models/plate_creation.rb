# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PlateCreation < AssetCreation
  include_plate_named_scope :parent

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  belongs_to :parent, class_name: 'Plate'

  def record_creation_of_children
    parent.events.create_plate!(child_purpose, child, user)
  end
  private :record_creation_of_children

  module Children
    def self.included(base)
      base.class_eval do
        include_plate_named_scope :child
        belongs_to :child, class_name: 'Plate'

        validates_unassigned(:child)
      end
    end

    def target_for_ownership
      child
    end
    private :target_for_ownership

    def children
      [child]
    end
    private :children

    def create_children!
      self.child = child_purpose.create!(location: parent.location)
    end
    private :create_children!
  end
  include Children

  module CreationChild
    def self.included(base)
      base.class_eval do
        has_many :plate_creations, foreign_key: :child_id
      end
    end
  end
end
