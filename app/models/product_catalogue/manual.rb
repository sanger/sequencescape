# frozen_string_literal: true
class ProductCatalogue::Manual # rubocop:todo Style/Documentation
  attr_reader :product

  def initialize(catalogue, submission_attributes)
    @product =
      catalogue.product_with_criteria(submission_attributes[:order_role]) || catalogue.product_with_criteria(nil)
  end
end
