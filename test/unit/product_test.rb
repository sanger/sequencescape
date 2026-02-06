# frozen_string_literal: true

require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  context 'A product' do
    should have_many :submission_templates
    should have_many :orders
    should have_many :product_criteria

    should validate_presence_of :name

    should 'only allow one active product with each name' do
      @product_a = create(:product)
      assert_raise(ActiveRecord::RecordInvalid) { @product_b = create(:product, name: @product_a.name) }
    end

    should 'allow products with the same name if one is deprecated' do
      @product_a = create(:product, deprecated_at: Time.zone.now)
      @product_b = create(:product, name: @product_a.name)

      assert_predicate @product_b, :valid?
    end

    should 'not be destroyable' do
      @product_a = create(:product)

      # ActiveRecord::RecordNotDestroyed is the Rails4 exception for this
      # Added here as Rails 2 is a bit useless with appropriate exceptions
      assert_raise(ActiveRecord::RecordNotDestroyed) { @product_a.destroy! }
    end

    should 'be deprecatable' do
      @product_a = create(:product)
      @product_a.deprecate!

      assert_predicate @product_a, :deprecated?
      assert_not_equal @product_a.deprecated_at, nil
    end
  end

  context 'Product' do
    setup do
      @product_a = create(:product, deprecated_at: Time.zone.now)
      @product_b = create(:product)
    end

    context '::active' do
      should 'return non-deprecated products only' do
        assert_includes Product.active, @product_b, 'Did not return active products'
        assert_not Product.active.include?(@product_a), 'Returned deprecated products'
      end
    end
  end
end
