# frozen_string_literal: true
# Creates a single tube with just one parent.
class TubeFromPlateCreation < AssetCreation
  belongs_to :child, class_name: 'Tube'
  belongs_to :parent, class_name: 'Plate'

  private

  def target_for_ownership
    child
  end

  def children
    [child]
  end

  def create_children!
    self.child = child_purpose.create!
  end
end
