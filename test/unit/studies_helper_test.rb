# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class StudiesHelperTest < ActiveSupport::TestCase
  context StudiesHelper do
    setup do
      @helper = Class.new
      @helper.send(:extend, StudiesHelper)
    end

    context '#display_owner' do
      setup do
        @study = mock('Study')
      end

      teardown do
        assert_equal @expected, @helper.display_owner(@study)
      end

      should 'return "Not available" for no owner' do
        @study.stubs(:owner).returns(nil)
        @expected = 'Not available'
      end

      should 'return the owner name' do
        @study.stubs(:owner).returns(mock('Owner', name: 'John Smith'))
        @expected = 'John Smith'
      end
    end

    context '#display_owners' do
      setup do
        @roles = []
      end

      teardown do
        study = mock('Study', roles: @roles)
        assert_equal @expected, @helper.display_owners(study)
      end

      should 'return "Not available" for no owners' do
        @expected = 'Not available'
      end

      should 'return the single owner name' do
        @roles << mock('Role', name: 'owner', users: [mock('User', name: 'John Smith')])
        @expected = 'John Smith'
      end

      should 'comma-separate multiple owners' do
        @roles << mock('Role', name: 'owner', users: [mock('User', name: 'John Smith'), mock('User', name: 'Jane Doe')])
        @expected = 'John Smith, Jane Doe'
      end
    end
  end
end
