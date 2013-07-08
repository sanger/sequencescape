class SpecificTubeCreation < TubeCreation
  class ChildPurpose < ActiveRecord::Base
    set_table_name('specific_tube_creation_purposes')
    belongs_to :specific_tube_creation
    belongs_to :tube_purpose, :class_name => 'Purpose'
  end

  has_many :creation_child_purposes, :class_name => 'SpecificTubeCreation::ChildPurpose'
  has_many :child_purposes, :through => :creation_child_purposes, :source => :tube_purpose

  validates_presence_of :child_purposes

  def set_child_purposes=(uuids)
    self.child_purposes = uuids.map {|uuid| Uuid.find_by_external_id(uuid).resource }
  end

  def create_children!
    self.children = (child_purposes).map { |child_purpose| child_purpose.create! }
  end
  private :create_children!

  def multiple_purposes
   true
  end


end
