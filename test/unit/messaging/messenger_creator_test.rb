#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require 'test_helper'

class MessengerCreatorTest < ActiveSupport::TestCase

  context '#messenger_creator' do

    setup do

      @purpose =           Factory.build :plate_purpose
      @messenger_creator = Factory.build :messenger_creator, :purpose => @purpose
      @plate =             Factory.build :plate, :plate_purpose => @purpose

    end

    should 'create a messenger' do
      @messenger = @messenger_creator.create!(@plate)
      assert @messenger.is_a?(Messenger)
      assert_equal @messenger.target, @plate
      assert_equal @messenger.root, 'a_plate'
      assert_equal @messenger.template, 'FluidigmPlateIO'
    end

    should 'be handled automatically by the purpose' do
      @start_count = Messenger.count
      @plate.cherrypick_completed
      assert 1, Messenger.count - @start_count
    end

  end

end
