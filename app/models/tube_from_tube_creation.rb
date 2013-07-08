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

  def record_creation_of_children
#    children.each { |child| parent.events.create_tube!(child_purpose, child, user) }
  end
  private :record_creation_of_children
end
