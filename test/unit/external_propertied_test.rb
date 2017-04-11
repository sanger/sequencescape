# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class ExternalPropertied < ActiveRecord::Base
  include ExternalProperties
  self.table_name = :assets
end

class ExternalPropertiedTest < ActiveSupport::TestCase
  context 'A model using external properties' do
    should have_many :external_properties

    setup do
      @test_subject = ExternalPropertied.create(name: 'TestObject')
      assert @test_subject.valid?
    end

    context '#get_external_value(key)' do
      test_value = 'Test'
      setup do
        # we use "test" as :test is saved as weird serialized stuff
        @test_subject.external_properties.create(key: 'test', value: test_value)
      end
      should 'have the right value' do
        assert_equal test_value, @test_subject.get_external_value(:test)
      end
      context 'where given key does not exist' do
        should 'return nil' do
          assert_nil @test_subject.get_external_value(:badgers)
        end
      end
    end
  end
end
