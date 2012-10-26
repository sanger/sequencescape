require 'test_helper'

class Core::Io::Base::JsonFormattingBehaviour::Output::StreamTest < ActiveSupport::TestCase
  context Core::Io::Base::JsonFormattingBehaviour::Output::Stream do
    setup do
      @buffer = StringIO.new
      @stream = Core::Io::Base::JsonFormattingBehaviour::Output::Stream.new(@buffer)
    end

    should 'generate empty object on open empty' do
      @stream.open { |stream| true }
      assert_equal('{}', @buffer.string)
    end

    should 'allow for array generation' do
      @stream.open do |stream|
        stream.array('key', [1,2,3]) do |stream, object|
          stream.encode(object)
        end
      end
      assert_equal('{"key":[1,2,3]}', @buffer.string)
    end

    should 'generate a block for access' do
      @stream.open do |stream|
        stream.send(:[], 'block') do |stream|
          stream['key'] = 'value'
        end
      end
      assert_equal('{"block":{"key":"value"}}', @buffer.string)
    end

    context 'separate multiple attributes' do
      should 'simple' do
        @stream.open do |stream|
          stream['key1'] = 'value1'
          stream['key2'] = 'value2'
        end
        assert_equal('{"key1":"value1","key2":"value2"}', @buffer.string)
      end

      should 'structured' do
        @stream.open do |stream|
          stream.send(:[], 'block1') { |stream| stream['key'] = 'value' }
          stream.send(:[], 'block2') { |stream| stream['key'] = 'value' }
        end
        assert_equal(
          '{"block1":{"key":"value"},"block2":{"key":"value"}}',
          @buffer.string
        )
      end

      should 'structured with multiple' do
        @stream.open do |stream|
          stream.send(:[], 'block1') do |stream|
            stream['key1'] = 'value1'
            stream['key2'] = 'value2'
          end
          stream.send(:[], 'block2') do |stream|
            stream['key'] = 'value'
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
        @stream.open { |stream| stream['key'] = @value }
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
        @expected = %Q{{"a":"b"}}
      end

      should 'array' do
        @value = ['a','b']
        @expected = %Q{["a","b"]}
      end

      should 'symbol' do
        @value, @expected = :value, '"value"'
      end
    end
  end
end
