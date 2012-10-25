require 'test_helper'

class Core::Io::JsonOutputTest < ActiveSupport::TestCase
  module BasicMethods
    def object_json(*args)
      {}
    end
  end

  def encoder_for(mappings)
    Object.new.tap do |encoder|
      class << encoder
        extend BasicMethods
        extend Core::Io::Base::JsonFormattingBehaviour::Output
      end
    end.singleton_class.tap do |encoder|
      encoder.generate_object_to_json_mapping(mappings)
    end
  end
  private :encoder_for

  def object_to_encode(attributes)
    OpenStruct.new(attributes.reverse_merge(
      :uuid       => 'uuid',
      :created_at => 'created_at_now',
      :updated_at => 'updated_at_now'
    ))
  end
  private :object_to_encode

  def json_results(attributes)
    attributes.reverse_merge(
      'uuid'       => 'uuid',
      'created_at' => 'created_at_now',
      'updated_at' => 'updated_at_now'
    )
  end
  private :json_results

  def decode(json)
    json
  end
  private :decode

  context Core::Io::Base::JsonFormattingBehaviour do
    context 'simple attribute' do
      context 'simple JSON' do
        context 'value cases' do
          teardown do
            encoder = encoder_for('attribute' => 'json')

            assert_equal(
              json_results('json' => @value),
              decode(encoder.object_json(object_to_encode(:attribute => @value), {}))
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
            @value = [ '1', '2', '3' ]
          end

          should 'handle numbers' do
            @value = 1
          end

          should 'handle times' do
            @value = Time.parse('2012-10-25 12:39')
          end
        end

        should 'output multiple values' do
          encoder = encoder_for(
            'attribute1' => 'json1',
            'attribute2' => 'json2'
          )

          assert_equal(
            json_results(
              'json1' => 'value1',
              'json2' => 'value2'
            ),
            decode(encoder.object_json(object_to_encode(
              :attribute1 => 'value1',
              :attribute2 => 'value2'
            ), {}))
          )
        end
      end

      context 'nested JSON attribute' do
        context 'value cases' do
          teardown do
            encoder = encoder_for('attribute' => 'nested.json')

            assert_equal(
              json_results('nested' => { 'json' => @value }),
              decode(encoder.object_json(object_to_encode(:attribute => @value), {}))
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
          encoder = encoder_for(
            'attribute1' => 'nested.json1',
            'attribute2' => 'nested.json2'
          )

          assert_equal(
            json_results(
              'nested' => {
                'json1' => 'value1',
                'json2' => 'value2'
              }
            ),
            decode(encoder.object_json(object_to_encode(
              :attribute1 => 'value1',
              :attribute2 => 'value2'
            ), {}))
          )
        end
      end
    end

    context 'nested attribute' do
      context 'when intermediate is absent' do
        should 'be nil if JSON attribute simple' do
          encoder = encoder_for('level1.attribute' => 'json')

          assert_equal(
            json_results('json' => nil),
            decode(encoder.object_json(object_to_encode({ :level1 => nil }), {}))
          )
        end

        should 'be absent if JSON attribute is complicated' do
          encoder = encoder_for('level1.attribute' => 'nested.json')

          assert_equal(
            json_results({}),
            decode(encoder.object_json(object_to_encode({ :level1 => nil }), {}))
          )
        end
      end

      context 'when intermediate present' do
        context 'simple values' do
          teardown do
            encoder = encoder_for('level1.attribute' => 'json')

            assert_equal(
              json_results(
                'json' => @value
              ),
              decode(encoder.object_json(object_to_encode(
                :level1 => OpenStruct.new(:attribute => @value)
              ), {}))
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
          encoder = encoder_for(
            'level1.attribute1' => 'nested.json1',
            'level2.attribute2' => 'nested.json2'
          )

          assert_equal(
            json_results(
              'nested' => {
                'json1' => 'value1',
                'json2' => 'value2'
              }
            ),
            decode(encoder.object_json(object_to_encode(
              :level1 => OpenStruct.new(:attribute1 => 'value1'),
              :level2 => OpenStruct.new(:attribute2 => 'value2')
            ), {}))
          )
        end

        should 'output multiple ungrouped values' do
          encoder = encoder_for(
            'level1.attribute1' => 'nested1.json1',
            'level2.attribute2' => 'nested2.json2'
          )

          assert_equal(
            json_results(
              'nested1' => { 'json1' => 'value1' },
              'nested2' => { 'json2' => 'value2' }
            ),
            decode(encoder.object_json(object_to_encode(
              :level1 => OpenStruct.new(:attribute1 => 'value1'),
              :level2 => OpenStruct.new(:attribute2 => 'value2')
            ), {}))
          )
        end
      end
    end
  end
end
