require 'test_helper'

class Cherrypick::Strategy::PickPlateTest < ActiveSupport::TestCase
  context Cherrypick::Strategy::PickPlate do
    context '#dimension' do
      [ 96, 384 ].each do |size|
        context "when the plate size is #{size}" do
          should 'return plate width if purpose picked in rows' do
            plate = Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => size, :cherrypick_direction => 'row'))
            assert_equal(Map.plate_width(size), plate.dimension)
          end

          should 'return plate length if purpose picked in column' do
            plate = Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => size, :cherrypick_direction => 'column'))
            assert_equal(Map.plate_length(size), plate.dimension)
          end
        end
      end
    end

    context 'empty plate' do
      setup do
        @target = Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => 96, :cherrypick_direction => 'row'))
      end

      context '#available' do
        should 'be the size of the plate' do
          assert_equal(96, @target.available)
        end
      end

      context '#empty' do
        should 'be true' do
          assert(@target.empty?)
        end
      end

      context '#used' do
        should 'be zero' do
          assert(@target.used.zero?)
        end
      end

      context '#overlap' do
        should 'be zero' do
          assert(@target.overlap.zero?)
        end
      end

      context '#remainder' do
        should 'be zero' do
          assert(@target.remainder.zero?)
        end
      end

      context '#to_a' do
        should 'be empty' do
          assert(@target.to_a.empty?)
        end
      end

      context '#species' do
        should 'be empty with no picks' do
          assert(@target.species.empty?)
        end

        should 'be empty with empty picks' do
          @target.concat([ Cherrypick::Strategy::Empty ])
          assert(@target.species.empty?)
        end

        should 'be the last pick species if there have been picks' do
          @target.concat([ OpenStruct.new(:species => [ :last ]) ])
          assert_equal([:last], @target.species)
        end
      end
    end

    context 'partial plate' do
      setup do
        @target = Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => 96, :cherrypick_direction => 'column'), 12, [:plate])
      end

      context '#available' do
        should 'be less than plate size' do
          assert_equal(96 - 12, @target.available)
        end
      end

      context '#empty' do
        should 'be false' do
          assert(!@target.empty?)
        end
      end

      context '#used' do
        should 'be size of partial usage' do
          assert_equal(12, @target.used)
        end
      end

      context '#overlap' do
        should 'be what is left over after modulus by dimension' do
          assert_equal(4, @target.overlap)
        end
      end

      context '#remainder' do
        teardown do
          @target = Cherrypick::Strategy::PickPlate.new(OpenStruct.new(:size => 96, :cherrypick_direction => 'column'), @filled)
          assert_equal(@expected, @target.remainder)
        end

        should 'be empty space left in dimension' do
          @filled, @expected = 12, 4
        end

        should 'be zero if the entire space is empty' do
          @filled, @expected = 8, 0
        end
      end

      context '#to_a' do
        should 'represent the occupied space as empty' do
          assert_equal(
            ([ Cherrypick::Strategy::Empty ] * 12).map(&:representation),
            @target.to_a
          )
        end
      end

      context '#species' do
        should 'be the species in the last non-empty well' do
          assert_equal([:plate], @target.species)
        end

        should 'be the species in the last non-empty well after empty pick' do
          @target.concat([ Cherrypick::Strategy::Empty ])
          assert_equal([:plate], @target.species)
        end

        should 'be the last pick species if there have been picks' do
          @target.concat([ OpenStruct.new(:species => [ :last ]) ])
          assert_equal([:last], @target.species)
        end
      end
    end
  end
end
