# frozen_string_literal: true

require 'test_helper'

class SubmissionTemplateTest < ActiveSupport::TestCase
  context 'A Order Template' do
    should validate_presence_of :product_catalogue

    setup do
      @template = FactoryBot.build :submission_template
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
    setup { @order = Order.new }
    context 'with a comment' do
      setup do
        @comment = 'my comment'
        @order.comments = @comment
      end
    end

    context 'without input_field_infos' do
      setup do
        @test_request_typ_b = create :library_creation_request_type
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
