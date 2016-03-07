#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PooledPlateCreation < AssetCreation

  class ParentAssociation < ActiveRecord::Base
    self.table_name =('asset_creation_parents')
    belongs_to :asset_creation
    belongs_to :parent, :class_name => 'Asset'
  end

  has_many :parent_associations, :foreign_key=>'asset_creation_id', :class_name => 'PooledPlateCreation::ParentAssociation'

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  has_many :parents, :through => :parent_associations, :class_name => 'Plate'

  include_plate_named_scope :parents

  def parent
    parents.first
  end

  def record_creation_of_children
    parents.each{|parent| parent.events.create_plate!(child_purpose, child, user)}
  end
  private :record_creation_of_children

  def connect_parent_and_children
    parents.each { |parent| AssetLink.create_edge!(parent, child) }
  end
  private :connect_parent_and_children

  include PlateCreation::Children

end
