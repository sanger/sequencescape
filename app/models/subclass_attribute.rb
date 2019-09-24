class SubclassAttribute < ApplicationRecord
  belongs_to :attributable, polymorphic: true

  validates :name, uniqueness: { scope: :attributable_id, case_sensitive: false }
end
