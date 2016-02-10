#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
FactoryGirl.define do
  factory :product_catalogue do |pc|
    pc.name      { |x| FactoryGirl.generate :product_catalogue_name }
  end

  factory :single_product_catalogue, :parent => :product_catalogue do |pc|
    pc.selection_behaviour 'SingleProduct'
  end

  factory :product do |product|
    product.name            { FactoryGirl.generate :product_name }
    product.deprecated_at   nil
  end

  factory :product_criteria do |pc|
    pc.product       {|product| product.association(:product) }
    pc.stage         'stock'
    pc.behaviour     'Basic'
    pc.configuration { {:total_micrograms=>{:greater_than=>50}} }
  end
end
