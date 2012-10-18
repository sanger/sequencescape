require 'test_helper'

class Cherrypick::Strategy::OptimumTest < ActiveSupport::TestCase
  context Cherrypick::Strategy::Optimum do
    context '#filters' do
      should 'ensure no overflow, best fit of empty space' do
        assert_equal(
          [
            Cherrypick::Strategy::Filter::ByOverflow,
            Cherrypick::Strategy::Filter::ByEmptySpaceUsage,
            Cherrypick::Strategy::Filter::BestFit
          ],
          Cherrypick::Strategy::Optimum.filters
        )
      end
    end
  end
end
