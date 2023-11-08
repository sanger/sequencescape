# frozen_string_literal: true
class ProductCatalogue::SingleProduct
  attr_reader :product

  def initialize(catalogue, _submission_attributes)
    @product = catalogue.products.first
  end
end
