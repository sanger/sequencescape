module Billing
  # the table should contain the same products as agresso database
  # product name should correspond to the name in agresso database
  # the name is used to query agresso database to find product code
  class Product < ApplicationRecord
    enum category: { library_creation: 0, sequencing: 1 }

    belongs_to :billing_product_catalogue, class_name: 'Billing::ProductCatalogue'
    has_many :requests
    validates :name, presence: true, uniqueness: true
    validates :category, presence: true
  end
end
