# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.


# Product catalogues provide a means of associating products with a submission
# template. selection_behaviour can allow a submission template to
# select an appropriate product.
# Ideally we want to deprecate submission templates in favour of
# products.

class ProductCatalogue < ActiveRecord::Base

  UndefinedBehaviour = Class.new(StandardError)

  has_many :submission_templates, inverse_of: :product_catalogue
  has_many :product_product_catalogues, inverse_of: :product_catalogue, dependent: :destroy
  has_many :products, through: :product_product_catalogues

  validates_presence_of :name
  validates_presence_of :selection_behaviour
  validate :selection_behaviour_exists?, if: :selection_behaviour?

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
        self.create!(arguments) do |catalogue|
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

  private

  def selection_behaviour_exists?
    # We can't use const_defined? here as it doesn't trigger rails autoloading.
    # We could probably use the autoloading API more directly, but it doesn't
    # seem to be intended to be used outside of Rails itself.
    ProductCatalogue.const_get(selection_behaviour)
    true
  rescue NameError
    errors.add(:selection_behaviour, "#{selection_behaviour} is not recognized")
    false
  end

  def selection_class
    raise UndefinedBehaviour, "No selection behaviour names #{selection_behaviour}" unless selection_behaviour_exists?
    ProductCatalogue.const_get(selection_behaviour)
  end

end
