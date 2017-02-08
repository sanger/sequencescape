# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

require 'test_helper'

class Core::Io::JsonOutputTest < ActiveSupport::TestCase
  module BasicMethods
    def object_json(_object, options)
      options[:stream]
    end
  end

  def encoder_for(mappings)
    Object.new.tap do |encoder|
      class << encoder
        extend BasicMethods
        extend Core::Io::Base::JsonFormattingBehaviour::Output

        def self.json_root
          'encoded'
        end
      end
    end.singleton_class.tap do |encoder|
      encoder.generate_object_to_json_mapping(mappings)
    end
  end
  private :encoder_for

  def object_to_encode(attributes)
    OpenStruct.new(attributes.reverse_merge(
      created_at: 'created_at_now',
      updated_at: 'updated_at_now'
    ))
  end
  private :object_to_encode

  def json_results(attributes)
    {
      'encoded' => attributes.reverse_merge(
        'created_at' => 'created_at_now',
        'updated_at' => 'updated_at_now'
      )
    }
  end
  private :json_results

  def decode(json)
    ActiveSupport::JSON.decode("{#{json.string}}")
  end
  private :decode

  context Core::Io::Base::JsonFormattingBehaviour do
    setup do
      @stream = StringIO.new
      @options = { stream: Core::Io::Json::Stream.new(@stream) }
    end

    context 'resource' do
      should 'handle objects with UUIDs'
    end

    context 'simple attribute' do
      context 'simple JSON' do
        context 'value cases' do
          teardown do
            encoder_for(
              'attribute' => 'json'
            ).object_json(
              object_to_encode(attribute: @value),
              @options
            )

            assert_equal(
              json_results('json' => @expected || @value),
              decode(@stream)
            )
          end

          should 'handle nil' do
            @value = nil
          end

          should 'handle non-nil' do
            @value = 'attribute_value'
          end

          should 'handle hashes' do
            @value = { 'a' => 1, 'b' => 2 }
          end

          should 'handle arrays' do
            @value = ['1', '2', '3']
          end

          should 'handle numbers' do
            @value = 1
          end

          should 'handle times' do
            @value, @expected = Time.parse('2012-10-25 12:39'), 'Thu Oct 25 12:39:00 +0100 2012'
          end
        end

        should 'output multiple values' do
          encoder_for(
            'attribute1' => 'json1',
            'attribute2' => 'json2'
          ).object_json(
            object_to_encode(
              attribute1: 'value1',
              attribute2: 'value2'
            ),
            @options
          )

          assert_equal(
            json_results(
              'json1' => 'value1',
              'json2' => 'value2'
            ),
            decode(@stream)
          )
        end
      end

      context 'nested JSON attribute' do
        context 'value cases' do
          teardown do
            encoder_for(
              'attribute' => 'nested.json'
            ).object_json(
              object_to_encode(attribute: @value),
              @options
            )

            assert_equal(
              json_results('nested' => { 'json' => @value }),
              decode(@stream)
            )
          end

          should 'handle nil' do
            @value = nil
          end

          should 'handle non-nil' do
            @value = 'attribute_value'
          end
        end

        should 'output multiple values' do
          encoder_for(
            'attribute1' => 'nested.json1',
            'attribute2' => 'nested.json2'
          ).object_json(
            object_to_encode(
              attribute1: 'value1',
              attribute2: 'value2'
            ),
            @options
          )

          assert_equal(
            json_results(
              'nested' => {
                'json1' => 'value1',
                'json2' => 'value2'
              }
            ),
            decode(@stream)
          )
        end
      end
    end

    context 'nested attribute' do
      context 'when intermediate is absent' do
        should 'be nil if JSON attribute simple' do
          encoder_for(
            'level1.attribute' => 'json'
          ).object_json(
            object_to_encode(level1: nil),
            @options
          )

          assert_equal(
            json_results({}),
            decode(@stream)
          )
        end

        should 'be absent if JSON attribute is complicated' do
          encoder_for(
            'level1.attribute' => 'nested.json'
          ).object_json(
            object_to_encode(level1: nil),
            @options
          )

          assert_equal(
            json_results('nested' => {}),
            decode(@stream)
          )
        end
      end

      context 'when intermediate present' do
        context 'simple values' do
          teardown do
            encoder_for(
              'level1.attribute' => 'json'
            ).object_json(
              object_to_encode(level1: OpenStruct.new(attribute: @value)),
              @options
            )

            assert_equal(
              json_results(
                'json' => @value
              ),
              decode(@stream)
            )
          end

          should 'handle nil' do
            @value = nil
          end

          should 'handle non-nil' do
            @value = 'attribute_value'
          end
        end
      end

      context 'multiple values' do
        should 'output multiple values' do
          encoder_for(
            'level1.attribute1' => 'nested.json1',
            'level2.attribute2' => 'nested.json2'
          ).object_json(
            object_to_encode(
              level1: OpenStruct.new(attribute1: 'value1'),
              level2: OpenStruct.new(attribute2: 'value2')
            ),
            @options
          )

          assert_equal(
            json_results(
              'nested' => {
                'json1' => 'value1',
                'json2' => 'value2'
              }
            ),
            decode(@stream)
          )
        end

        should 'output multiple ungrouped values' do
          encoder_for(
            'level1.attribute1' => 'nested1.json1',
            'level2.attribute2' => 'nested2.json2'
          ).object_json(
            object_to_encode(
              level1: OpenStruct.new(attribute1: 'value1'),
              level2: OpenStruct.new(attribute2: 'value2')
            ),
            @options
          )

          assert_equal(
            json_results(
              'nested1' => { 'json1' => 'value1' },
              'nested2' => { 'json2' => 'value2' }
            ),
            decode(@stream)
          )
        end
      end
    end
  end
end
