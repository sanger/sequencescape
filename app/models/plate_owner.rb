# frozen_string_literal: true
class PlateOwner < ApplicationRecord
  belongs_to :user
  belongs_to :plate
  belongs_to :eventable, polymorphic: true

end
