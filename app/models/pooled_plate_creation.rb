# frozen_string_literal: true
# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PooledPlateCreation < AssetCreation
  attr_accessor :barcode

  has_many :parent_associations, foreign_key: 'asset_creation_id', class_name: 'AssetCreation::ParentAssociation'

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  has_many :parents, through: :parent_associations, class_name: 'Labware'

  include_plate_named_scope :parents

  def parent
    parents.first
  end

  def record_creation_of_children
    parents.each { |parent| parent.events.create_plate!(child_purpose, child, user) }
  end
  private :record_creation_of_children

  def connect_parent_and_children
    parents.each { |parent| AssetLink.create_edge!(parent, child) }
  end
  private :connect_parent_and_children

  include PlateCreation::Children
end
