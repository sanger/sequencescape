module Billing
  # the table should contain the same products as agresso database
  # product name should correspond to the name in agresso database
  # the name is used to query agresso database to find product code
  class Product < ActiveRecord::Base
    belongs_to :product_catalogue, class_name: Billing::ProductCatalogue, inverse_of: :products
    validates :name, presence: true, uniqueness: true
  end
end
