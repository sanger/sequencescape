# frozen_string_literal: true

require 'test_helper'

class MessengerCreatorTest < ActiveSupport::TestCase
  context '#messenger_creator' do
    setup do
      @purpose = FactoryBot.build(:plate_purpose)
      @plate = FactoryBot.build(:plate, plate_purpose: @purpose)
    end

    context 'with SelfFinder' do
      setup do
        @messenger_creator = FactoryBot.build(:messenger_creator, purpose: @purpose)
        @start_count = Messenger.count
      end

      should 'create a messenger' do
        @messenger = @messenger_creator.create!(@plate)

        assert_kind_of Messenger, @messenger
        assert_equal @messenger.target, @plate
        assert_equal 'a_plate', @messenger.root
        assert_equal 'FluidigmPlateIo', @messenger.template
      end

      should 'be handled automatically by the purpose' do
        @purpose.messenger_creators << @messenger_creator
        @plate.cherrypick_completed

        assert_equal 1, Messenger.count - @start_count
      end
    end

    context 'with WellFinder' do
      setup do
        @messenger_creator =
          build(:messenger_creator, purpose: @purpose, target_finder_class: 'WellFinder', root: 'well')
        @start_count = Messenger.count
        @plate.save
        3.times { @plate.wells << build(:well) }
      end

      should 'create a messenger' do
        @messengers = @messenger_creator.create!(@plate)

        assert_kind_of Array, @messengers
        assert_equal 3, @messengers.length

        @plate.wells.each { |well| assert_includes @messengers.map(&:target), well }

        assert_equal 'well', @messengers.first.root
        assert_equal 'FluidigmPlateIo', @messengers.first.template
      end

      should 'be handled automatically by the purpose' do
        @purpose.messenger_creators << @messenger_creator
        @plate.cherrypick_completed

        assert_equal 3, Messenger.count - @start_count
      end
    end
  end
end
