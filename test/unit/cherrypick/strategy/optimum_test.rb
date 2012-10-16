require 'test_helper'

class Cherrypick::Strategy::OptimumTest < ActiveSupport::TestCase
  def request(submission_id, plex_size = nil)
    OpenStruct.new(:submission_id => submission_id, :plex_size => plex_size)
  end
  private :request

  def plexes(*plexes)
    plexes.flatten.each_with_index.map { |s,i| [request(i+1, s)] * s }.flatten
  end
  private :plexes

  def plate(size, dimension, used = 0)
    Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => size)).tap do |plate|
      plate.stubs(:dimension).returns(dimension)
      plate.instance_variable_get(:@wells).concat([ '' ] * used)
    end
  end
  private :plate

  Full = Object.new.tap do |full|
    class << full
      def inspect
        'Full'
      end
    end
  end

  def perform_pick(plex_levels, expected)
    requests, picked, plate = plexes(plex_levels), [], plate(96, 8)
    plate.singleton_class.send(:define_method, :used) { picked.size }

    until requests.empty?
      pick, requests = @strategy.choose_next_plex_from(requests, plate)
      picked.concat(pick)
    end

    # Not really bothered by which plex goes where, more that the size of the plexes is optimum
    assert_equal(
      expected.map { |x| x.is_a?(Array) ? x : [ Full ] * x }.flatten,
      picked.map { |v| (v == Cherrypick::Strategy::Empty) ? v : Full }
    )
  end
  private :perform_pick

  context Cherrypick::Strategy::Optimum do
    setup do
      @purpose  = OpenStruct.new
      @strategy = Cherrypick::Strategy::Optimum.new(@purpose)
    end

    context '#choose_next_plex_from' do
      context 'simple cases' do
        teardown do
          requests = [request(1), request(2), request(1), request(2), request(2)]
          pick, rest = @strategy.choose_next_plex_from(requests, plate(4, 4, @used))

          picked_requests = @picked.map(&requests.method(:[]))
          assert_equal(picked_requests, pick)
          assert_equal(requests - picked_requests, rest)
        end

        should 'pick an empty plex if plate is full' do
          @used, @picked = 4, []
        end

        should 'pick the largest plex for an empty plate' do
          @used, @picked = 0, [1,3,4]
        end

        should 'pick the plex that fits the space' do
          @used, @picked = 2, [0,2]
        end

        should 'pick the plex that optimally fills the space' do
          @used, @picked = 1, [1,3,4]
        end
      end

      should 'pick a blank plex to pad plate when no plex fits' do
        requests = [request(1), request(2), request(1), request(2), request(2)]
        pick, rest = @strategy.choose_next_plex_from(requests, plate(4, 4, 3))

        assert_equal([Cherrypick::Strategy::Empty], pick)
        assert_equal(requests, rest)
      end

      should 'avoid picking large plexes that would then leave empty space' do
        pick, _ = @strategy.choose_next_plex_from(plexes(8, 2, 2), plate(24, 8, 12))

        assert_equal(2, pick.size)
      end

      context 'real world issues' do
        should 'not fail to pick' do
          perform_pick(
            [ 12, 8, 2, 2, 1, 1 ],
            [ 12, 2, 2, 8, 1, 1 ]
          )
        end

        should 'fill empty space with empty wells' do
          perform_pick(
            [ 12, 8, 2, 1 ],
            [ 12, 2, 1, [Cherrypick::Strategy::Empty], 8 ]
          )
        end
      end
    end
  end
end
