module Billing
  # a group of products
  # if there is more than one product in a group,
  # it should have a differentiator to be able to find the right product
  class ProductCatalogue < ActiveRecord::Base
    has_many :billing_products, class_name: Billing::Product, foreign_key: :billing_product_catalogue_id
    has_many :request_types
    accepts_nested_attributes_for :billing_products
    validates :name, presence: true, uniqueness: true

    def find_product_for_request(request)
      return billing_products.first if single_product?
      billing_products.find_by(differentiator_value: request.send(differentiator))
    end

    def single_product?
      billing_products.length == 1
    end
  end
end
