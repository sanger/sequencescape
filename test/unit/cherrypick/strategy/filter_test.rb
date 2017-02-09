# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

require 'test_helper'

class Cherrypick::Strategy::FilterTest < ActiveSupport::TestCase
  def plex(size, species = 'unknown')
    [OpenStruct.new(species: Array(species))] * size
  end
  private :plex

  def plate(*species)
    OpenStruct.new(species: species)
  end
  private :plate

  context Cherrypick::Strategy::Filter::ShortenPlexesToFit do
    setup { @target = Cherrypick::Strategy::Filter::ShortenPlexesToFit.new }

    should 'shorten plexes to the available space on the plate' do
      plexes = [mock('plex 1'), mock('plex 2')]
      plexes.each_with_index { |p, i| p.expects(:slice).with(0, 10).returns("short #{i + 1}") }

      assert_equal(
        ['short 1', 'short 2'],
        @target.call(plexes, OpenStruct.new(available: 10))
      )
    end
  end

  context Cherrypick::Strategy::Filter::ByOverflow do
    setup { @target = Cherrypick::Strategy::Filter::ByOverflow.new }

    should 'choose plexes that do not overflow the plate' do
      plexes = [plex(2), plex(3), plex(2), plex(1)]
      assert_equal(
        [plexes[0], plexes[2], plexes[3]],
        @target.call(plexes, OpenStruct.new(used: 10, size: 12))
      )
    end
  end

  context Cherrypick::Strategy::Filter::ByEmptySpaceUsage do
    setup { @target = Cherrypick::Strategy::Filter::ByEmptySpaceUsage.new }

    should 'return all plexes if there is no overlap' do
      plexes = [plex(4), plex(8), plex(12)]

      assert_equal(
        plexes,
        @target.call(plexes, OpenStruct.new(overlap: 0, dimension: 8))
      )
    end

    should 'return plexes that fill the space' do
      plexes = [plex(4), plex(8), plex(2), plex(1)]
      assert_equal(
        [plexes[0], plexes[2], plexes[3]],
        @target.call(plexes, OpenStruct.new(overlap: 4, dimension: 8))
      )
    end

    should 'return plexes that do not cause empty space themselves' do
      plexes = [plex(8), plex(4), plex(12), plex(20)]
      assert_equal(
        [plexes[1], plexes[2], plexes[3]],
        @target.call(plexes, OpenStruct.new(overlap: 4, dimension: 8))
      )
    end
  end

  context Cherrypick::Strategy::Filter::BestFit do
    setup { @target = Cherrypick::Strategy::Filter::BestFit.new }

    should 'sort largest plex first when no overlap' do
      plexes = [plex(4), plex(8), plex(12), plex(1)]
      assert_equal(
        plexes.sort_by(&:size).reverse,
        @target.call(plexes, OpenStruct.new(overlap: 0))
      )
    end

    should 'sort plexes to reduce empty space' do
      plexes = [plex(1), plex(2), plex(4), plex(3), plex(12)]
      plate  = OpenStruct.new(overlap: 4, available: 12).tap do |plate|
        class << plate
          def space_after_adding(plex)
            (available - plex.size) % 8
          end
        end
      end
      assert_equal(
        [plexes[4], plexes[2], plexes[3], plexes[1], plexes[0]],
        @target.call(plexes, plate)
      )
    end
  end

  context Cherrypick::Strategy::Filter::BySpecies do
    setup do
      @target = Cherrypick::Strategy::Filter::BySpecies.new
      @plexes = [plex(1, 'human'), plex(1, 'fish'), plex(1, 'snail')]
    end

    teardown do
      assert_equal(@expected, @target.call(@plexes, @plate))
    end

    should 'order the plexes so that the same species plexes are first' do
      @plate, @expected = plate('snail'), [@plexes[2], @plexes[0], @plexes[1]]
    end

    should 'order the plexes so that any of the same species plexes are first' do
      @plate, @expected = plate('snail', 'human'), [@plexes[0], @plexes[2], @plexes[1]]
    end

    should 'give back the plexes unchanged if there are no matching species plexes' do
      @plate, @expected = plate('unknown'), @plexes
    end

    should 'give back the plexes unchanged when the plate is empty' do
      @plate, @expected = plate, @plexes
    end
  end

  context Cherrypick::Strategy::Filter::InternallyOrderPlexBySubmission do
    setup { @target = Cherrypick::Strategy::Filter::InternallyOrderPlexBySubmission.new }

    should 'order each plex internally by the positions in the submission' do
      requests = (1..5).map { |i| OpenStruct.new(index_in_submission: i) }

      assert_equal(
        [requests],
        @target.call([requests.reverse], nil)
      )
    end
  end
end
