#
# Bait libraries come in two types, custom and standard, which can affect costs.
#
class BaitLibraryType < ApplicationRecord
  include SharedBehaviour::Named

  # category is used for billing, to differentiate between products with Custom and Standard bait libraries
  enum category: { standard: 0, custom: 1 }

  has_many :bait_libraries

  # Types have names, need to be unique
  validates :name, :category, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  scope :visible, -> { where(visible: true) }

  def hide
    self.visible = false
    save!
  end
end
