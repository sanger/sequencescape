module Aker
  class Product < ApplicationRecord
    validates :name, :description, presence: true
    validates :name, uniqueness: true

    has_many :product_processes, foreign_key: :aker_product_id, dependent: :destroy
    has_many :processes, through: :product_processes

    def as_json(_options = {})
      {
        product: {
          id: id,
          name: name,
          description: description,
          processes: processes
        }
      }
    end
  end
end
