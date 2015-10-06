#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
Factory.define :product_catalogue do |pc|
  pc.name      { |x| Factory.next :product_catalogue_name }
end

Factory.define :single_product_catalogue, :parent => :product_catalogue do |pc|
  pc.selection_behaviour 'SingleProduct'
end

Factory.define :product do |product|
  product.name            { Factory.next :product_name }
  product.deprecated_at   nil
end
