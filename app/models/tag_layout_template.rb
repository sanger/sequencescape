# This is a layout template for tags.  Think of it as a partially created TagLayout, defining only the tag
# group that will be used and the actual TagLayout implementation that will do the work.
class TagLayoutTemplate < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :tag_group
  validates_presence_of :tag_group

  validates_presence_of :name
  validates_uniqueness_of :name

  validates_presence_of :layout_class_name

  delegate :direction, :to => :layout_class

  def layout_class
    layout_class_name.constantize
  end
  private :layout_class

  # Create a TagLayout instance that does the actual work of laying out the tags.
  def create!(attributes = {}, &block)
    layout_class.create!(attributes.merge(:tag_group => tag_group), &block)
  end
end
