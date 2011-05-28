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
  validates_unassigned(:child)

  # Before creating an instance we create the child plate and ensure the asset link is present.  This doesn't
  # copy any of the wells as the plate itself is initially empty.
  before_create :create_child_plate
  def create_child_plate
    self.child = child_plate_purpose.create!
    connect_parent_and_child
    connect_child_to_parent_study
  end
  private :create_child_plate

  def connect_parent_and_child
    AssetLink.connect(self.parent, self.child)
  end
  private :connect_parent_and_child

  def connect_child_to_parent_study
    RequestFactory.create_asset_requests([ self.child.id ], self.parent.study.id) if self.parent.study.present?
  end
  private :connect_child_to_parent_study
end
