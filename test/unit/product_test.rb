#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

require "test_helper"

class ProductTest < ActiveSupport::TestCase
  context "A product" do
    should_have_many :submission_templates, :requests
    # TODO:
    # should_have_one  :critera

    should_validate_presence_of :name


    should 'only allow one active product with each name' do
      @product_a = Factory :product
      assert_raise(ActiveRecord::RecordInvalid) { @product_b = Factory :product, :name=> @product_a.name }
    end

    should 'allow products with the same name if one is deprecated' do
      @product_a = Factory :product, :deprecated_at => Time.now
      @product_b = Factory :product, :name=> @product_a.name
      assert @product_b.valid?
    end

    should 'not be destroyable' do
      @product_a = Factory :product
      # ActiveRecord::RecordNotDestroyed is the Rails4 exception for this
      # Added here as Rails 2 is a bit useless with appropriate exceptions
      assert_raise(ActiveRecord::RecordNotDestroyed) { @product_a.destroy }
    end

    should 'be deprecatable' do
      @product_a = Factory :product
      @product_a.deprecate!
      assert @product_a.deprecated?
      assert @product_a.deprecated_at != nil
    end
  end

  context 'Product' do

    setup do
      @product_a = Factory :product, :deprecated_at => Time.now
      @product_b = Factory :product
    end

    context '::active' do
      should 'return non-deprecated products only' do
        assert Product.active.include?(@product_b), 'Did not return active products'
        assert !Product.active.include?(@product_a), 'Returned deprecated products'
      end
    end
  end
end
