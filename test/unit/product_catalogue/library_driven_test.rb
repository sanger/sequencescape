#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.

require File.dirname(__FILE__) + '/../../test_helper'

class LibraryDrivenTest < ActiveSupport::TestCase
  context "When using a ProductCatalogue that is library driven" do
    setup do
      @product = FactoryGirl.create :product
      @product2 = FactoryGirl.create :product
      @library_type = FactoryGirl.create :library_type
      @library_type2 = FactoryGirl.create :library_type

      @product_catalogue = FactoryGirl.create :product_catalogue_library_driven, :products => {
        :"#{@library_type.name}" => @product.name,
        :"#{@library_type2.name}" => @product2.name
      }

    end

    context "using a submission template that belongs to that catalogue" do
      setup do
        @submission_template = FactoryGirl.create :submission_template, {
         :product_catalogue => @product_catalogue,
         :library_type => @library_type
        }
      end

      should "selects the product criteria for the submission that belongs to the library type of the submission template" do
        assert_equal @product, @product_catalogue.product_for(@submission_template.submission_attributes)
      end
    end

  end
end
