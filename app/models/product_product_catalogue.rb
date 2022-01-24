# frozen_string_literal: true
# Association between a product and a catalogue.
# selection_criteria provides a means for catalogues with multiple
# products to select a suitable one.

class ProductProductCatalogue < ApplicationRecord
  belongs_to :product
  belongs_to :product_catalogue
end
