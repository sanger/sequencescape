#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class TubeFromTubeCreation < AssetCreation

  belongs_to :child, :class_name => 'Tube'
  belongs_to :parent, :class_name => 'Tube'

  def target_for_ownership
    child
  end
  private :target_for_ownership

  def children
    [self.child]
  end
  private :children

  def create_children!
    self.child = child_purpose.create!
  end
  private :create_children!

  def create_ancestor_plate!
    create_ancestor_asset!(parent.plate, child) if can_create_ancestor_plate?(parent.plate, child)
  end
  before_save :create_ancestor_plate!

  def record_creation_of_children
#    children.each { |child| parent.events.create_tube!(child_purpose, child, user) }
  end
  private :record_creation_of_children
end
