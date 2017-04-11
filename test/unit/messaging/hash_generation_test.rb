# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class HashGenerationTest < ActiveSupport::TestCase
  class ExampleModel
    attr_reader :association, :has_many_association, :name

    def initialize(name, association, has_many_association)
      @name, @association, @has_many_association = name, association, has_many_association
    end

    def destroyed?
      false
    end

    def updated_at
      Date.new(2013, 1, 2)
    end
  end

  class ExampleApi < Api::Base
    renders_model(::HashGenerationTest::ExampleModel)

    map_attribute_to_json_attribute(:name)

    with_association(:association) do
      map_attribute_to_json_attribute(:assn_var, 'association_value')
    end

    with_nested_has_many_association(:has_many_association) do
      map_attribute_to_json_attribute(:ham_assn_var, 'nested_value')

      with_nested_has_many_association(:has_many_more) do
        map_attribute_to_json_attribute(:ham_assn_var, 'nested_value_2')
      end
    end

    map_attribute_to_json_attribute(:updated_at)
  end

  context '#Api::Base' do
    setup do
      @test_assn = mock('assn')
      @test_has_many_more = mock('hasm_more_assn')
      @test_ham_assn = mock('hasm_assn')

      @example_model = ExampleModel.new('example', @test_assn, [@test_ham_assn])

      @test_assn.stubs(:assn_var).returns('example_2')
      @test_assn.stubs(:destroyed?).returns(false)
      @test_assn.stubs(:updated_at).returns(Date.new(2013, 1, 4))

      @test_ham_assn.stubs(:ham_assn_var).returns('example_3')
      @test_ham_assn.stubs(:destroyed?).returns(false)
      @test_ham_assn.stubs(:updated_at).returns(Date.new(2013, 1, 3))
      @test_ham_assn.stubs(:has_many_more).returns([@test_has_many_more])

      @test_has_many_more.stubs(:ham_assn_var).returns('example_4')
      @test_has_many_more.stubs(:destroyed?).returns(false)
      @test_has_many_more.stubs(:updated_at).returns(Date.new(2013, 1, 3))
    end

    context 'A simple model' do
      should 'generate the expected hash' do
        hash = ExampleApi.to_hash(@example_model)
        assert_equal({
          'name' => 'example',
          'association_value' => 'example_2',
          'has_many_association' => [{ 'nested_value' => 'example_3', 'has_many_more' => [{ 'nested_value_2' => 'example_4' }] }],
          'updated_at' => Date.new(2013, 1, 4)
        }, hash)
      end
    end

    context 'With newer sub_nested models' do
      setup do
        @test_has_many_more.stubs(:updated_at).returns(Date.new(2013, 1, 6))
      end

      should 'record an updated timestamp' do
        hash = ExampleApi.to_hash(@example_model)
        assert_equal({
          'name' => 'example',
          'association_value' => 'example_2',
          'has_many_association' => [{ 'nested_value' => 'example_3', 'has_many_more' => [{ 'nested_value_2' => 'example_4' }] }],
          'updated_at' => Date.new(2013, 1, 6)
        }, hash)
      end
    end
  end
end
