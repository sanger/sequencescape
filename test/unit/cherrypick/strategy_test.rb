require 'test_helper'

class Cherrypick::StrategyTest < ActiveSupport::TestCase
  def request(submission_id, barcode = 1)
    OpenStruct.new(:submission_id => submission_id, :barcode => barcode)
  end
  private :request

  context Cherrypick::Strategy::Empty do
    setup { @target = Cherrypick::Strategy::Empty }

    context '#barcode' do
      should 'be nil' do
        assert(@target.barcode.nil?)
      end
    end

    context '#representation' do
      should 'be the same as the cherrypick empty well representation' do
        assert(CherrypickTask::EMPTY_WELL, @target.representation)
      end
    end
  end

  context Cherrypick::Strategy do
    setup do
      @purpose  = PlatePurpose.find_by_name('WGS stock DNA') or raise "Cannot find plate purpose"
      @strategy = Cherrypick::Strategy.new(@purpose)
    end

    context '#wrap_plate' do
      should 'return an empty plate when the plate is not specified' do
        assert_equal(
          @strategy.send(:create_empty_plate).to_a,
          @strategy.send(:wrap_plate, nil).to_a
        )
      end

      context 'return partially filled plate' do
        teardown do
          assert_equal(
            Cherrypick::Strategy::PickPlate.new(@purpose, 12).to_a,
            @strategy.send(:wrap_plate, @plate).to_a
          )
        end

        should 'contiguous wells' do
          @plate = @purpose.create!(:do_not_create_wells).tap do |plate|
            @purpose.well_locations.slice(0, 12).each do |location|
              plate.wells.create!(:map => location)
            end
          end
        end

        should 'non-contiguous wells' do
          @plate = @purpose.create!(:do_not_create_wells).tap do |plate|
            plate.wells.create!(:map => @purpose.well_locations[11])
          end
        end
      end
    end

    context '#pick' do
      should 'return empty plates for no requests' do
        pick_list = @strategy.send(:_pick, [], OpenStruct.new)
        assert([], pick_list)
      end

      should 'raise an error if there is no pick for an empty plate' do
        assert_raises(Cherrypick::Strategy::PickFailureError) do
          @strategy.stubs(:choose_next_plex_from).returns([ [], [] ]) # Pretend no pick fits
          @strategy.send(:_pick, [request(1)], OpenStruct.new(:max_beds => 1))
        end
      end

      should 'return a single plate with one request' do
        request = request(1)
        @strategy.stubs(:choose_next_plex_from).returns([ [request], [] ])

        pick_list = @strategy.send(:_pick, [request], OpenStruct.new(:max_beds => 1))
        assert([[request]], pick_list)
      end

      should 'return two plates if the robot beds is too small' do
        # Calls go like this:
        # 1. From all requests pick the first request, put it on plate
        # 2. From remaining request pick the request, can't put it on plate as robot too large, try again
        # 4. From remaining request pick the request, put it on plate
        requests = [request(1, 1), request(2, 2)]
        @strategy.stubs(:choose_next_plex_from).with(requests,        anything).returns([ [requests.first], [requests.last] ]).once
        @strategy.stubs(:choose_next_plex_from).with([requests.last], anything).returns([ [requests.last],  [] ]).twice

        pick_list = @strategy.send(:_pick, requests, OpenStruct.new(:max_beds => 1))
        assert([[requests.first],[requests.last]], pick_list)
      end
    end
  end
end
