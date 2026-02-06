# frozen_string_literal: true

require 'test_helper'

class ProductCriteriaAdvancedTest < ActiveSupport::TestCase
  context 'a configured criteria' do
    setup do
      @params = {
        'failed' => {
          concentration: {
            greater_than: 500
          },
          measured_volume: {
            greater_than: 100
          }
        },
        'unprocessable' => {
          concentration: {
            greater_than: 50
          },
          measured_volume: {
            greater_than: 10
          }
        }
      }
    end

    context 'with a list of target wells' do
      setup do
        @well_attribute =
          create(:well_attribute, concentration: 800, current_volume: 100, gel_pass: 'OKAY', gender_markers: %w[M M U])
        @well = create(:well, well_attribute: @well_attribute)

        @target_wells = create_list(:well, 7)
        @target_wells[4].well_attribute.update(concentration: 30, updated_at: 1.hour.from_now)
        @criteria = ProductCriteria::Advanced.new(@params, @well, @target_wells)
      end
      should 'get the most recent target well from the supplied list' do
        assert_equal @criteria.most_recent_concentration_from_target_well_by_updating_date,
                     @target_wells[4].get_concentration
        @criteria2 = ProductCriteria::Advanced.new(@params, @well, nil)

        assert_nil @criteria2.most_recent_concentration_from_target_well_by_updating_date
      end
      should 'get the most recent concentration from normalization' do
        assert_equal 30, @criteria.concentration_from_normalization
        @criteria2 = ProductCriteria::Advanced.new(@params, @well, nil)

        assert_nil @criteria2.concentration_from_normalization
      end
    end

    context 'with a good well' do
      setup do
        @well_attribute = create(:well_attribute, concentration: 800, measured_volume: 200)
        @well = create(:well, well_attribute: @well_attribute)
        @criteria = ProductCriteria::Advanced.new(@params, @well)
      end

      should '#qc_decision should return "passed"' do
        assert_empty @criteria.comment
        assert_equal 'passed', @criteria.qc_decision, 'Well failed when it should have passed'
      end
    end

    context 'with a bad well' do
      setup do
        @well_attribute = create(:well_attribute, concentration: 200, measured_volume: 50)
        @well = create(:well, well_attribute: @well_attribute)
        @criteria = ProductCriteria::Advanced.new(@params, @well)
      end

      should '#qc_decision should return "failed"' do
        assert_equal 'failed', @criteria.qc_decision, 'Well passed when it should have failed'
        assert_equal ['Concentration too low', 'Measured volume too low'], @criteria.comment
      end
    end

    context 'with a very bad well' do
      setup do
        @well_attribute = create(:well_attribute, concentration: 1, measured_volume: 30_000)
        @well = create(:well, well_attribute: @well_attribute)
        @criteria = ProductCriteria::Advanced.new(@params, @well)
      end

      should '#qc_decision should return "unprocessable"' do
        assert_equal 'unprocessable', @criteria.qc_decision, 'Well passed when it should have failed'
        assert_equal ['Concentration too low'], @criteria.comment
      end
    end
  end
end
