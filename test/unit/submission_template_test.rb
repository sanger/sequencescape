# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class SubmissionTemplateTest < ActiveSupport::TestCase
  context 'A Order Template' do
    should validate_presence_of :product_catalogue

    setup do
      @template = FactoryGirl.build :submission_template
      @product = create(:product)
      @template.product_catalogue.products << @product
    end

    should 'be able to create a new order' do
      order = @template.new_order
      assert order
      assert order.is_a?(Order)
      assert_equal @product, order.product
    end
  end

  context 'A Order' do
    setup do
      @workflow = create :submission_workflow, key: 'microarray_genotyping'
      @order = Order.new(workflow: @workflow)
    end
    context 'with a comment' do
      setup do
        @comment = 'my comment'
        @order.comments = @comment
      end

      should 'be savable as a template' do
        template = SubmissionTemplate.new_from_submission('template 1', @order)
        assert template
        assert template.is_a?(SubmissionTemplate)
      end

      context 'saved as a template' do
        setup do
          @template_name = 'template 2'
          @template = SubmissionTemplate.new_from_submission(@template_name, @order)
        end

        should 'set the name to template' do
          assert_equal @template_name, @template.name
        end

        should 'set parameters to template' do
          assert @template.submission_parameters
          assert_equal @comment, @template.submission_parameters[:comments]
        end
      end
    end

    context 'without input_field_infos' do
      setup do
        @test_request_typ_b = create :library_creation_request_type
        @test_request_typ_b
        @test_request_type = create :sequencing_request_type
        @order.request_types = [@test_request_typ_b, @test_request_type]
        @order.request_type_ids_list = [[@test_request_typ_b.id], [@test_request_type.id]]
      end

      should 'load the parameters properly' do
        assert_equal 6, @order.input_field_infos.size
        assert_equal [37, 54, 76, 108], field('Read length').selection
        assert_equal 54, field('Read length').default_value
        assert_equal ['Standard'], field('Library type').selection
        assert_equal 'Standard', field('Library type').default_value
      end
    end
  end

  def field(field_name)
    @order.input_field_infos.detect { |ifi| ifi.display_name == field_name } || raise("#{field_name} field not found")
  end
end
