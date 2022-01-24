# frozen_string_literal: true
# Creating an instance of this class causes the target to become converted to the new
# plate purpose
class PlateConversion < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :target, class_name: 'Plate'
  belongs_to :user
  belongs_to :purpose, class_name: 'PlatePurpose'

  belongs_to :parent, class_name: 'Plate'

  after_create :convert_target

  private

  def convert_target
    target.convert_to(purpose)
    AssetLink.create_edge(parent, target) if parent.present?
  end
end
