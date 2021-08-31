# frozen_string_literal: true
class Permission < ApplicationRecord
  belongs_to :permissable, polymorphic: true
end
