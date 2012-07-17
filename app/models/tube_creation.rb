class TubeCreation < AssetCreation
  class ChildTube < ActiveRecord::Base
    set_table_name('tube_creation_children')
    belongs_to :tube_creation
    belongs_to :tube
  end

  has_many :child_tubes, :class_name => 'TubeCreation::ChildTube'
  has_many :children, :through => :child_tubes, :source => :tube

  validates_each(:parent, :unless => :parent_nil?, :allow_blank => true) do |record, attr, value|
    record.errors.add(:parent, 'has no pooling information') if record.parent.pools.empty?
  end

  def target_for_ownership
    children
  end
  private :target_for_ownership

  def create_children!
    self.children = (1..parent.pools.size).map { |_| child_purpose.create! }
  end
  private :create_children!

  def record_creation_of_children
#    children.each { |child| parent.events.create_tube!(child_purpose, child, user) }
  end
  private :record_creation_of_children
end
