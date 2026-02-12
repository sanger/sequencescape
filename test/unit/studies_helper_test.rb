# frozen_string_literal: true

require 'test_helper'

class StudiesHelperTest < ActiveSupport::TestCase
  context StudiesHelper do
    setup do
      @helper = Class.new
      @helper.send(:extend, StudiesHelper)
    end

    context '#display_owners' do
      setup { @owners = [] }

      teardown do
        study = mock('Study', owners: @owners)

        assert_equal @expected, @helper.display_owners(study)
      end

      should 'return "Not available" for no owners' do
        @expected = 'Not available'
      end

      should 'return the single owner name' do
        @owners << mock('User', name: 'John Smith')
        @expected = 'John Smith'
      end

      should 'comma-separate multiple owners' do
        @owners << mock('User', name: 'John Smith') << mock('User', name: 'Jane Doe')
        @expected = 'John Smith, Jane Doe'
      end
    end
  end
end
