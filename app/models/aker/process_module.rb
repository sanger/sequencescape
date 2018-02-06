module Aker
  class ProcessModule < ApplicationRecord
    validates :name, presence: true, uniqueness: true

    def null?
      false
    end
  end
end
