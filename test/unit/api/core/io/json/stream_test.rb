# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

require 'test_helper'

class Core::Io::Json::StreamTest < ActiveSupport::TestCase
  context Core::Io::Json::Stream do
    setup do
      @buffer = StringIO.new
      @stream = Core::Io::Json::Stream.new(@buffer)
    end

    should 'generate empty object on open empty' do
      @stream.open { |_stream| true }
      assert_equal('{}', @buffer.string)
    end

    should 'allow for array generation' do
      @stream.open do |stream|
        stream.array('key', [1, 2, 3]) do |stream, object|
          stream.encode(object)
        end
      end
      assert_equal('{"key":[1,2,3]}', @buffer.string)
    end

    should 'generate a block for access' do
      @stream.open do |stream|
        stream.block('block') do |stream|
          stream.attribute('key', 'value')
        end
      end
      assert_equal('{"block":{"key":"value"}}', @buffer.string)
    end

    context 'separate multiple attributes' do
      should 'simple' do
        @stream.open do |stream|
          stream.attribute('key1', 'value1')
          stream.attribute('key2', 'value2')
        end
        assert_equal('{"key1":"value1","key2":"value2"}', @buffer.string)
      end

      should 'structured' do
        @stream.open do |stream|
          stream.block('block1') { |stream| stream.attribute('key', 'value') }
          stream.block('block2') { |stream| stream.attribute('key', 'value') }
        end
        assert_equal(
          '{"block1":{"key":"value"},"block2":{"key":"value"}}',
          @buffer.string
        )
      end

      should 'structured with multiple' do
        @stream.open do |stream|
          stream.block('block1') do |stream|
            stream.attribute('key1', 'value1')
            stream.attribute('key2', 'value2')
          end
          stream.block('block2') do |stream|
            stream.attribute('key', 'value')
          end
        end
        assert_equal(
          '{"block1":{"key1":"value1","key2":"value2"},"block2":{"key":"value"}}',
          @buffer.string
        )
      end
    end

    context 'basic types' do
      teardown do
        @stream.open { |stream| stream.attribute('key', @value) }
        assert_equal(%Q{{"key":#{@expected}}}, @buffer.string)
      end

      should 'nil' do
        @value, @expected = nil, 'null'
      end

      should 'true' do
        @value, @expected = true, 'true'
      end

      should 'false' do
        @value, @expected = false, 'false'
      end

      should 'string' do
        @value, @expected = 'value', '"value"'
      end

      should 'integer' do
        @value, @expected = 1, '1'
      end

      should 'float' do
        @value, @expected = 1.01, '1.01'
      end

      should 'date' do
        @value, @expected = Date.new(2012, 10, 26), '"2012-10-26"'
      end

      should 'time' do
        @value, @expected = Time.parse('2012-10-26 09:35'), '"Fri Oct 26 09:35:00 +0100 2012"'
      end

      should 'hash' do
        @value = { 'a' => 'b' }
        @expected = '{"a":"b"}'
      end

      should 'array' do
        @value = ['a', 'b']
        @expected = '["a","b"]'
      end

      should 'symbol' do
        @value, @expected = :value, '"value"'
      end
    end
  end
end
