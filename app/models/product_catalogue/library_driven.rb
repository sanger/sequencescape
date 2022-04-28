# frozen_string_literal: true
class ProductCatalogue::LibraryDriven # rubocop:todo Style/Documentation
  attr_reader :product

  def initialize(catalogue, submission_attributes)
    # library_type_name will be set to nil if it was not defined
    # We can't use fetch here, as in some cases submission_attributes[:request_options] is nil
    # rather than just undefined.
    library_type_name = (submission_attributes[:request_options] || {})[:library_type]
    @product = catalogue.product_with_default(library_type_name)
  end
end
