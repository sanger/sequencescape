class SubclassAttribute < ApplicationRecord
  belongs_to :attributable, polymorphic: true

  validates_uniqueness_of :name, scope: :attributable_id
end
