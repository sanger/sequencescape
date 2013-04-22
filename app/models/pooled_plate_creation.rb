# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PooledPlateCreation < AssetCreation

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  has_many :parents, :class_name => 'Plate'

  include PlateCreation::Children

  def parent
    parents.first
  end

  def record_creation_of_children
    parents.each{|parent| parent.events.create_plate!(child_purpose, child, user)}
  end
  private :record_creation_of_children

end
