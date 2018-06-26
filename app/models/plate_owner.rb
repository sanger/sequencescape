
class PlateOwner < ApplicationRecord
  belongs_to :user
  belongs_to :plate
  belongs_to :eventable, polymorphic: true

  validates_presence_of :eventable
end
