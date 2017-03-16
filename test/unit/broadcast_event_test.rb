# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

class BroadcastEventTest < ActiveSupport::TestCase
  # This level of mocking is painful. It probably calls for splitting the test up, and testing templates
  # separately from the actual json generation.
  class TestSeed
    include ActiveModel::Model
    include ActiveModel::AttributeMethods
    # include ActiveRecord::AttributeMethods::Read
    define_attribute_methods :uuid, :friendly_name, :subject_type, :single_relation, :many_relation, :dynamic_relation, :id, :data_method_a

    attr_accessor :uuid, :friendly_name, :subject_type, :single_relation, :many_relation, :dynamic_relation, :id, :data_method_a

    def self.primary_key; :id; end

    def attributes
      {
        'uuid' => @uuid,
        'friendly_name' => @friendly_name,
        'subject_type' => @subject_type,
        'single_relation' => @single_relation,
        'many_relation' => @many_relation,
        'dynamic_relation' => @dynamic_relation,
        'id' => @id,
        'data_method_a' => @data_method_a
      }
    end

    def marked_for_destruction?
      false
    end

    def destroyed?
      false
    end

    def new_record?
      false
    end

    def _read_attribute(attribute)
      attributes[attribute]
    end

    def self.base_class
      self
    end
  end

  TestSubject = Struct.new(:uuid, :friendly_name, :subject_type)
  DynamicSubject = Struct.new(:target, :data_method_b)

  def assert_subject(subject, role_type)
    assert @event.subjects, 'No subjects found'
    test_subject = @event.subjects.detect { |s| s.uuid == subject.uuid }

    assert test_subject, "Could not find #{subject.uuid} in: #{@event.subjects.map { |s| s.try(:uuid) }.join(', ')}"

    assert_equal subject.friendly_name, test_subject.friendly_name
    assert_equal subject.subject_type, test_subject.subject_type
    assert_equal role_type, test_subject.role_type
  end

  def assert_metadata(key, value)
    assert_equal value, @event.metadata[key]
  end

  # As BroadcastEvents is primarily about making events easy to configure
  # lets generate a test instance
  class ExampleEvent < BroadcastEvent
    set_event_type 'example_event'

    seed_class TestSeed

    # The seed itself can be a subject
    seed_subject :seed
    # Methods that yield a single object
    has_subject :single, :single_relation
    # Methods that yield an array
    has_subjects :many, :many_relation
    # Blocks that define more complicated relationships
    has_subject(:block) { |ts, _e| ts.dynamic_relation.target }

    has_metadata :data_a, :data_method_a
    has_metadata(:data_b) { |ts, _e| ts.dynamic_relation.data_method_b }

    has_metadata(:data_c) { |_ts, e| e.accessible }

    def accessible
      'value_c'
    end
  end

  context 'BroadcastEvent' do
    should 'not be directly instantiated' do
      assert_raise(StandardError) { BroadcastEvent.new }
    end
  end

  context 'ExampleEvent' do
    should 'be instantiated' do
      assert ExampleEvent.new
    end

    context 'with a seed' do
      setup do
        @single         = TestSubject.new('000', 'single_subject', 'single_type')
        @many_one       = TestSubject.new('001', 'many_subject_1', 'many_type')
        @many_two       = TestSubject.new('002', 'many_subject_2', 'many_type')
        @dynamic_target = TestSubject.new('003', 'dynamic_subject', 'dynamic_type')
        @value_b = 'value_b'
        @dynamic = DynamicSubject.new(@dynamic_target, @value_b)
        @value_a = 'value_a'
        @user = create :user, email: 'example@example.com'
        @time = DateTime.parse('2012-03-11 10:22:42')
        # :uuid, :friendly_name, :subject_type, :single_relation, :many_relation, :dynamic_relation, :id, :data_method_a
        @seed = TestSeed.new(
          uuid: '004',
          friendly_name: 'seed_subject',
          subject_type: 'seed_type',
          single_relation: @single,
          many_relation: [@many_one, @many_two],
          dynamic_relation: @dynamic,
          id: 1,
          data_method_a: @value_a)
        @event = ExampleEvent.new(seed: @seed, user: @user, created_at: @time)
      end

      should 'find subjects with a 1 to 1 relationship' do
        assert_subject(@single, 'single')
      end

      should 'find subjects with a 1 to many relationship' do
        assert_subject(@many_one, 'many')
        assert_subject(@many_two, 'many')
      end

      should 'find subjects with a block relationship' do
        assert_subject(@dynamic_target, 'block')
      end

      should 'find the seed subject' do
        assert_subject(@seed, 'seed')
      end

      should 'have five subjects in total' do
        # Just to make sure we're not registering extra subjects
        assert_equal 5, @event.subjects.length
      end

      should 'find metadata by simple calls' do
        assert_metadata('data_a', @value_a)
      end

      should 'find metadata by block calls' do
        assert_metadata('data_b', @value_b)
      end

      should 'scope metadata on event' do
        assert_metadata('data_c', 'value_c')
      end

      should 'find all metadata as a hash' do
        assert_equal({ 'data_a' => @value_a, 'data_b' => @value_b, 'data_c' => 'value_c' }, @event.metadata)
      end

      # Put it all together
      should 'generate the expected json' do
        @event.save!

        expected_json = {
          'event' => {
          'uuid' => @event.uuid,
          'event_type' => 'example_event',
          'occured_at' => '2012-03-11T10:22:42+00:00',
          'user_identifier' => 'example@example.com',
          'subjects' => [
            {
              'role_type' => 'seed',
              'subject_type' => 'seed_type',
              'friendly_name' => 'seed_subject',
              'uuid' => '004'
            },
            {
              'role_type' => 'single',
              'subject_type' => 'single_type',
              'friendly_name' => 'single_subject',
              'uuid' => '000'
            },
            {
              'role_type' => 'many',
              'subject_type' => 'many_type',
              'friendly_name' => 'many_subject_1',
              'uuid' => '001'
            },
            {
              'role_type' => 'many',
              'subject_type' => 'many_type',
              'friendly_name' => 'many_subject_2',
              'uuid' => '002'
            },
            {
              'role_type' => 'block',
              'subject_type' => 'dynamic_type',
              'friendly_name' => 'dynamic_subject',
              'uuid' => '003'
            }
          ],
          'metadata' => {
            'data_a' => 'value_a',
            'data_b' => 'value_b',
            'data_c' => 'value_c'
          }
          },
          'lims' => 'SQSCP'
        }

        assert_equal expected_json, JSON.parse(@event.to_json)
      end
    end
  end
end
