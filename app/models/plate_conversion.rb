# Creating an instance of this class causes the target to become converted to the new
# plate purpose
class PlateConversion < ActiveRecord::Base

  belongs_to :target, :class_name => 'Plate'
  belongs_to :user
  belongs_to :purpose, :class_name => 'PlatePurpose'

  validates_presence_of :target, :purpose, :user

  after_create :convert_target

  private

  def convert_target
    target.convert_to(purpose)
  end

end
