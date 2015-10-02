#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

# Product catalogues provide a means of associating products with a submission
# template. selection_behaviour can allow a submission template to
# select an appropriate product.
# Ideally we want to deprecate submission templates in favour of
# products.

class ProductCatalogue < ActiveRecord::Base

  has_many :submission_templates, :inverse_of => :product_catalogue
  has_many :product_product_catalogues, :inverse_of => :product_catalogue
  has_many :products, :through => :product_product_catalogues
end
