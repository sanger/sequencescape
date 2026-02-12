# frozen_string_literal: true

require 'test_helper'

class ProductCriteriaTest < ActiveSupport::TestCase
  context 'A product criteria' do
    should belong_to :product
    should validate_presence_of :product
    should validate_presence_of :stage
    should validate_presence_of :behaviour

    setup do
      @product_a = create(:product)
      @criteria_a =
        create(:product_criteria, product: @product_a, configuration: { total_micrograms: { greater_than: 50 } })
    end

    should 'only allow one active criteria per product per stage' do
      assert_raise(ActiveRecord::RecordInvalid) { create(:product_criteria, product: @product_a) }
    end

    should 'allow multiple active criteria with different stages' do
      @criteria_b = create(:product_criteria, product: @product_a, stage: 'another_stage')

      assert_predicate @criteria_b, :valid?
    end

    should 'allow products with the same name if one is deprecated' do
      @criteria_a.deprecated_at = Time.zone.now
      @criteria_a.save
      @criteria_2 = create(:product_criteria, product: @product_a)

      assert_predicate @criteria_2, :valid?
    end

    should 'automatically version criteria' do
      assert_equal 1, @criteria_a.version
      @criteria_a.deprecated_at = Time.zone.now
      @criteria_a.save
      @criteria_b = create(:product_criteria, product: @product_a)

      assert_equal 2, @criteria_b.version
    end

    should 'not be destroyable' do
      # ActiveRecord::RecordNotDestroyed is the Rails4 exception for this
      # Added here as Rails 2 is a bit useless with appropriate exceptions
      assert_raise(ActiveRecord::RecordNotDestroyed) { @criteria_a.destroy! }
    end

    should 'be deprecatable' do
      @criteria_a.deprecate!

      assert_predicate @criteria_a, :deprecated?
      assert_not_equal @criteria_a.deprecated_at, nil
    end

    should 'be otherwise immutable' do
      @criteria_a.configuration = { something: 'else' }
      assert_raise(ActiveRecord::RecordNotSaved) { @criteria_a.save! }
    end

    should 'serialize configuration' do
      assert_kind_of Hash, @criteria_a.configuration
      @criteria_a.reload

      assert_kind_of Hash, @criteria_a.configuration
    end

    should 'validate wells with the provided criteria' do
      well_attribute = create(:well_attribute, concentration: 800, current_volume: 100)
      well = create(:well, well_attribute:)
      assesment = @criteria_a.assess(well)

      assert_kind_of ProductCriteria::Basic, assesment
      assert_predicate assesment, :passed?
    end

    should 'be able to take metrics' do
      well = { concentration: 800, current_volume: 100, total_micrograms: 90 }
      assesment = @criteria_a.assess(well)

      assert_kind_of ProductCriteria::Basic, assesment
      assert_predicate assesment, :passed?
    end
  end
end
