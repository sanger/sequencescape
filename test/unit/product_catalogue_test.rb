# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require 'test_helper'

class ProductCatalogueTest < ActiveSupport::TestCase
  context 'A product catalogue' do
    should validate_presence_of :name
    should validate_presence_of :selection_behaviour

    context 'with single product behaviour' do
      setup do
        @catalogue = create :single_product_catalogue
        @product = create :product
        @catalogue.products << @product
      end

      context '#product_for' do
        should 'return the product' do
          assert_equal @product, @catalogue.product_for(attributes: :do_not_matter)
        end
      end
    end

    context 'with invalid behaviour' do
      should 'reject non-existant behaviours' do
        assert_raise(ActiveRecord::RecordInvalid) do
          create :product_catalogue, selection_behaviour: 'InvalidSelectionBehaviour'
        end
      end
    end

    context 'with global constants for behaviour' do
      should 'reject behaviours' do
        assert_raise(ActiveRecord::RecordInvalid) do
          create :product_catalogue, selection_behaviour: 'File'
        end
      end
    end
  end

  context 'ProductCatalogue::construct!' do
    setup do
      @catalogue_count = ProductCatalogue.count

      @existing_product = create :product, name: 'pre_existing'

      @product_count = Product.count
      @product_product_catalogue_count = ProductProductCatalogue.count

      catalogue_parameters = {
        name: 'test',
        selection_behaviour: 'SingleProduct',
        products: {
          'ambiguator_a' => 'pre_existing',
          'ambiguator_b' => 'novel'
        }
      }

      @constructed = ProductCatalogue.construct!(catalogue_parameters)
    end

    should 'create a catalogue' do
      assert @constructed
      assert_equal 1, ProductCatalogue.count - @catalogue_count
    end

    should 'only register novel products' do
      assert_equal 1, Product.count - @product_count
    end

    should 'link in each product' do
      assert_equal @existing_product, @constructed.product_with_criteria('ambiguator_a')
      assert_equal 'novel', @constructed.product_with_criteria('ambiguator_b').name
    end
  end
end
