# Creating an instance of this class causes a child plate, with the specified plate type, to be created from
# the parent.
class PlateCreation < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :user

  # There must be a parent plate from which to create a child.
  belongs_to :parent, :class_name => 'Plate'
  validates_presence_of :parent

  def parent_nil?
    parent.nil?
  end
  private :parent_nil?

  # The child plate type must be present and be one of the child types of the parent plates type.
  belongs_to :child_plate_purpose, :class_name => 'PlatePurpose'
  validates_presence_of :child_plate_purpose
  validates_each(:child_plate_purpose, :unless => :parent_nil?, :allow_blank => true) do |record, attr, child_plate_purpose|
    record.errors.add(:child_plate_purpose, 'is not a valid child plate type') unless record.parent.plate_purpose.child_plate_purposes.include?(child_plate_purpose)
  end

  # This is the child that is created from the parent.  It cannot be assigned before validation.
  belongs_to :child, :class_name => 'Plate'
  validates_each(:child) do |record, attr, value|
    record.errors.add(:child, 'cannot be assigned') if value.present?
  end

  # Before creating an instance we create the child plate and ensure the asset link is present.  This doesn't
  # copy any of the wells as the plate itself is initially empty.
  before_create :create_child_plate
  def create_child_plate
    self.child = child_plate_purpose.create!
    AssetLink.create_edge(self.parent, self.child)
  end
  private :create_child_plate
end
