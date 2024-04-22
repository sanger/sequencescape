# frozen_string_literal: true

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
      @stream.open { |stream| stream.array('key', [1, 2, 3]) { |stream, object| stream.encode(object) } }
      assert_equal('{"key":[1,2,3]}', @buffer.string)
    end

    should 'generate a block for access' do
      @stream.open { |stream| stream.block('block') { |stream| stream.attribute('key', 'value') } }
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
        assert_equal('{"block1":{"key":"value"},"block2":{"key":"value"}}', @buffer.string)
      end

      should 'structured with multiple' do
        @stream.open do |stream|
          stream.block('block1') do |stream|
            stream.attribute('key1', 'value1')
            stream.attribute('key2', 'value2')
          end
          stream.block('block2') { |stream| stream.attribute('key', 'value') }
        end
        assert_equal('{"block1":{"key1":"value1","key2":"value2"},"block2":{"key":"value"}}', @buffer.string)
      end
    end

    context 'basic types' do
      teardown do
        @stream.open { |stream| stream.attribute('key', @value) }
        assert_equal("{\"key\":#{@expected}}", @buffer.string)
      end

      should 'nil' do
        @value = nil
        @expected = 'null'
      end

      should 'true' do
        @value = true
        @expected = 'true'
      end

      should 'false' do
        @value = false
        @expected = 'false'
      end

      should 'string' do
        @value = 'value'
        @expected = '"value"'
      end

      should 'integer' do
        @value = 1
        @expected = '1'
      end

      should 'float' do
        @value = 1.01
        @expected = '1.01'
      end

      should 'date' do
        @value = Date.new(2012, 10, 26)
        @expected = '"2012-10-26"'
      end

      should 'time' do
        @value = Time.parse('2012-10-26 09:35')
        @expected = '"Fri Oct 26 09:35:00 +0100 2012"' # rubocop:disable Rails/TimeZone
      end

      should 'ActiveSupport::TimeWithZone' do
        @value = Time.zone.parse('2012-10-26 09:35')
        @expected = '"2012-10-26 09:35:00 +0100"'
      end

      should 'hash' do
        @value = { 'a' => 'b' }
        @expected = '{"a":"b"}'
      end

      should 'array' do
        @value = %w[a b]
        @expected = '["a","b"]'
      end

      should 'symbol' do
        @value = :value
        @expected = '"value"'
      end
    end
  end
end
