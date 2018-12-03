module Billing
  # a group of products
  class ProductCatalogue < ApplicationRecord
    has_many :billing_products, class_name: 'Billing::Product', foreign_key: :billing_product_catalogue_id
    has_many :request_types
    accepts_nested_attributes_for :billing_products
    validates :name, presence: true, uniqueness: true

    def find_product_for_request(request)
      return billing_products.first if single_product?

      billing_products.find_by(identifier: request.billing_product_identifier)
    end

    def single_product?
      billing_products.size == 1
    end
  end
end
