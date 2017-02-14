# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

# Association between a product and a catalogue.
# selection_criteria provides a means for catalogues with multiple
# products to select a suitable one.

class ProductProductCatalogue < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_catalogue

  validates_presence_of :product
  validates_presence_of :product_catalogue
end
