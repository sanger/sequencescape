
require 'pry'
class ExtractionAttribute < ActiveRecord::Base
  include Uuid::Uuidable

  validates_presence_of :created_by

  # This is the target asset for which to update the state
  belongs_to :target, :class_name => 'Asset', :foreign_key => :target_id
  validates_presence_of :target

  validates_presence_of :attributes_update

  serialize :attributes_update

  after_create :update_performed
  def update_performed
    #puts attributes_update
    #target.update_attributes(attrs)
  end
  private :update_performed

end
