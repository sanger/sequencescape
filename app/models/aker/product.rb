module Aker
  class Product < ApplicationRecord
    validates :name, :description, :requested_biomaterial_type, :product_class, presence: true
    validates :name, uniqueness: true

    has_many :product_processes, foreign_key: :aker_product_id, dependent: :destroy
    has_many :processes, through: :product_processes

    belongs_to :catalogue, class_name: 'Catalogue', foreign_key: :aker_catalogue_id, required: true

    before_update :bump_product_version

    def as_json(_options = {})
      {
        id: id,
        name: name,
        description: description,
        product_version: product_version,
        availability: availability,
        requested_biomaterial_type: requested_biomaterial_type,
        product_class: product_class,
        processes: processes.collect { |p| p.as_json(product_id: id) }
      }
    end

    private

    def bump_product_version
      self.product_version = product_version + 1
    end
  end
end
