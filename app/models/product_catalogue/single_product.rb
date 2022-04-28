# frozen_string_literal: true
class ProductCatalogue::SingleProduct # rubocop:todo Style/Documentation
  attr_reader :product

  def initialize(catalogue, _submission_attributes)
    @product = catalogue.products.first
  end
end
