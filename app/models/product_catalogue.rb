# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015, 2016 Genome Research Ltd.

# Product catalogues provide a means of associating products with a submission
# template. selection_behaviour can allow a submission template to
# select an appropriate product.
# Ideally we want to deprecate submission templates in favour of
# products.

class ProductCatalogue < ActiveRecord::Base
  # Specify the behaviour classes that may be used to select a product
  # The behaviours take the catalogue and submission parameters and
  # return a product
  # Ensures:
  # - Classes get loaded properly
  # - Ruby Class loading can't be exploited to instantiate global classes
  include HasBehaviour
  has_behaviour LibraryDriven, behaviour_name: 'LibraryDriven'
  has_behaviour Manual, behaviour_name: 'Manual'
  has_behaviour SingleProduct, behaviour_name: 'SingleProduct'

  UndefinedBehaviour = Class.new(StandardError)

  has_many :submission_templates, inverse_of: :product_catalogue
  has_many :product_product_catalogues, inverse_of: :product_catalogue, dependent: :destroy
  has_many :products, through: :product_product_catalogues

  validates_presence_of :name
  validates_presence_of :selection_behaviour
  validates :selection_behaviour, inclusion: { in: registered_behaviours }

  class << self
    def construct!(arguments)
      ActiveRecord::Base.transaction do
        products = arguments.delete(:products)
        product_assocations = products.map do |criterion, product_name|
          {
            selection_criterion: criterion,
            product: Product.find_or_create_by(name: product_name)
          }
        end
        create!(arguments) do |catalogue|
          catalogue.product_product_catalogues.build(product_assocations)
        end
      end
    end
  end

  def product_for(submission_attributes)
    selection_class.new(self, submission_attributes).product
  end

  def product_with_criteria(criteria)
    products.find_by(product_product_catalogues: { selection_criterion: criteria })
  end

  def product_with_default(criteria)
    # Order of priorities to select a Product:
    # In a LibraryDriven selection we select the Product with this priorities:
    # 1- The product linked with the library type
    # 2- The first product linked with "nil" SelectionCriterion
    # 3- nil in any other case
    product_with_criteria(criteria) || product_with_criteria(nil)
  end

  private

  def selection_class
    self.class.with_behaviour(selection_behaviour) ||
     raise(UndefinedBehaviour, "No selection behaviour names #{selection_behaviour}")
  end
end
