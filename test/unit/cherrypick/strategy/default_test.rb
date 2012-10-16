require 'test_helper'

class Cherrypick::Strategy::DefaultTest < ActiveSupport::TestCase
  def request(submission_id)
    OpenStruct.new(:submission_id => submission_id)
  end
  private :request

  context Cherrypick::Strategy::Default do
    setup do
      @purpose  = OpenStruct.new
      @strategy = Cherrypick::Strategy::Default.new(@purpose)
      @requests = [request(1), request(2), request(1)]
    end

    context '#choose_next_plex_from' do
      should 'pick the first plex' do
        plex, remaining = @strategy.choose_next_plex_from(@requests, OpenStruct.new(:available => 2))
        assert_equal(plex, [@requests[0], @requests[2]])
        assert_equal(remaining, [@requests[1]])
      end

      should 'pick a subset of the first plex' do
        plex, remaining = @strategy.choose_next_plex_from(@requests, OpenStruct.new(:available => 1))
        assert_equal(plex, [@requests[0]])
        assert_equal(remaining, [@requests[1], @requests[2]])
      end

      should 'pick an empty plex if plate is full' do
        plex, remaining = @strategy.choose_next_plex_from(@requests, OpenStruct.new(:available => 0))
        assert_equal(plex, [])
        assert_equal(remaining, @requests)
      end
    end
  end
end
