##
# A lot type governs the behaviour of a lot

class LotType < ActiveRecord::Base

  include Uuid::Uuidable

  has_many :lots, :inverse_of => :lot_type
  belongs_to :target_purpose, :class_name => 'Purpose'

  validates_presence_of :name, :template_class
  validates_uniqueness_of :name

  def valid_template_class
    template_class.constantize
  end

  def create!(options)
    self.lots.create!(options)
  end

end
