# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class ProductCatalogue::SingleProduct
  attr_reader :product

  def initialize(catalogue, _submission_attributes)
    @product = catalogue.products.first
  end
end
