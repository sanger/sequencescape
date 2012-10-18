require 'test_helper'

class Cherrypick::Strategy::DefaultTest < ActiveSupport::TestCase
  context Cherrypick::Strategy::Default do
    context '#filters' do
      should 'makes plexes fit' do
        assert_equal(
          [
            Cherrypick::Strategy::Filter::ShortenPlexesToFit
          ],
          Cherrypick::Strategy::Default.filters
        )
      end
    end
  end
end
