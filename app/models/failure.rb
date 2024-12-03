# frozen_string_literal: true
class Failure < ApplicationRecord
  belongs_to :failable, polymorphic: true
end
