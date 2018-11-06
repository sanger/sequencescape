class Permission < ApplicationRecord
  belongs_to :permissable, polymorphic: true
end
