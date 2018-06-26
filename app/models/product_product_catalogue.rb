
# Association between a product and a catalogue.
# selection_criteria provides a means for catalogues with multiple
# products to select a suitable one.

class ProductProductCatalogue < ApplicationRecord
  belongs_to :product
  belongs_to :product_catalogue

  validates_presence_of :product
  validates_presence_of :product_catalogue
end
