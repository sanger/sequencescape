# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.

require 'test_helper'

class LibraryDrivenTest < ActiveSupport::TestCase
  context 'When using a ProductCatalogue that is library driven' do
    setup do
      def link_product_with_pc(product, product_catalogue, library_type_name)
        FactoryGirl.create :product_product_catalogue, product: product,
                                                       product_catalogue: product_catalogue,
                                                       selection_criterion: library_type_name
      end

      # We'll create a product catalogue that will contain [@product, @product2, @product3]
      @product = FactoryGirl.create :product
      @product2 = FactoryGirl.create :product
      @product3 = FactoryGirl.create :product

      @library_type = FactoryGirl.create :library_type, name: 'LibraryType 1'
      @library_type2 = FactoryGirl.create :library_type, name: 'LibraryType 2'

      @product_catalogue = FactoryGirl.create :library_driven_product_catalogue

      # The selection criterion is the library type name
      link_product_with_pc(@product, @product_catalogue, @library_type.name)
      link_product_with_pc(@product2, @product_catalogue, @library_type2.name)
    end

    context 'without a default product' do
      context 'using a submission template that belongs to that catalogue' do
        context 'with no library or incorrect type' do
          setup do
            @submission_template = FactoryGirl.create :submission_template, name: 'ST 1',
                                                                            product_catalogue: @product_catalogue,
                                                                            submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: [],
               request_options: { library_type: 'Another library' } }

            @submission_template2 = FactoryGirl.create :submission_template, name: 'ST 2',
                                                                             product_catalogue: @product_catalogue,
                                                                             submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: []
               }
          end
          should 'not select any product (return nil)' do
            order = @submission_template.new_order
            order2 = @submission_template2.new_order

            assert_equal nil, order.product
            assert_equal nil, order2.product
          end
        end
      end
    end

    context 'with a default product' do
      setup do
        # No selection criterion. Will be the default
        link_product_with_pc(@product3, @product_catalogue, nil)
      end
      context 'using a submission template that belongs to that catalogue' do
        context 'with a library type selected' do
          setup do
            @submission_template = FactoryGirl.create :submission_template, name: 'ST 1',
                                                                            product_catalogue: @product_catalogue,
                                                                            submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: [],
               request_options: { library_type: @library_type.name } }

            @submission_template2 = FactoryGirl.create :submission_template, name: 'ST 2',
                                                                             product_catalogue: @product_catalogue,
                                                                             submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: [],
               request_options: { library_type: @library_type2.name } }
          end

          should 'selects the right product for this submission using the library type' do
            order = @submission_template.new_order
            order2 = @submission_template2.new_order

            assert_equal @product, order.product
            assert_equal @product2, order2.product
          end
        end

        context 'without a library type selected' do
          setup do
            @submission_template3 = FactoryGirl.create :submission_template, name: 'ST 3',
                                                                             product_catalogue: @product_catalogue,
                                                                             submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: []
             }
          end

          should 'select the first product of the default products' do
            order3 = @submission_template3.new_order
            assert_equal @product3, order3.product
          end
        end
        context 'with a library type unsupported by the product catalogue' do
          setup do
            @submission_template4 = FactoryGirl.create :submission_template, name: 'ST 4',
                                                                             product_catalogue: @product_catalogue,
                                                                             submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: [],
               request_options: { library_type: 'Standard' } }
          end
          should 'select the first product of the default products' do
            order = @submission_template4.new_order
            assert_equal @product3, order.product
          end
        end
        context 'with a library type that matches more than one product' do
          setup do
            @product4 = FactoryGirl.create :product

            link_product_with_pc(@product4, @product_catalogue, @library_type.name)

            @submission_template5 = FactoryGirl.create :submission_template, name: 'ST 5',
                                                                             product_catalogue: @product_catalogue,
                                                                             submission_parameters: {
               workflow_id: 1,
               request_type_ids_list: [],
               request_options: { library_type: @library_type.name } }
          end
          should 'select the first product of the default products' do
            order = @submission_template5.new_order
            assert_equal @product, order.product
          end
        end
      end
    end
  end
end
