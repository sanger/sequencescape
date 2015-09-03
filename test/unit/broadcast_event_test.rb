#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"

class BroadcastEventTest < ActiveSupport::TestCase


  TestSeed    = Struct.new(:uuid,:friendly_name,:subject_type,:single_relation,:many_relation,:dynamic_relation,:id)
  class TestSeed
    def self.base_class; BroadcastEvent; end
  end
  TestSubject = Struct.new(:uuid,:friendly_name,:subject_type)
  DynamicSubject = Struct.new(:target)

  def assert_subject(subject,role_type)
    assert @event.subjects, "No subjects found"
    test_subject = @event.subjects.detect {|s| s.uuid == subject.uuid }

    assert test_subject, "Could not find #{subject.uuid} in: #{@event.subjects.map {|s| s.try(:uuid) }.join(', ')}"

    assert_equal subject.friendly_name, test_subject.friendly_name
    assert_equal subject.subject_type, test_subject.subject_type
    assert_equal role_type, test_subject.role_type
  end

  # As BroadcastEvents is primarily about making events easy to configure
  # lets generate a test instance
  class ExampleEvent < BroadcastEvent

    seed_class TestSeed

    # The seed itself can be a subject
    seed_subject :seed
    # Methods that yield a single object
    has_subject :single, :single_relation
    # Methods that yield an array
    has_subjects :many, :many_relation
    # Blocks that define more complicated relationships
    has_subject(:block) { |ts| ts.dynamic_relation.target }
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
        @single         = TestSubject.new('000','single_subject','single_type')
        @many_one       = TestSubject.new('001','many_subject_1','many_type')
        @many_two       = TestSubject.new('002','many_subject_1','many_type')
        @dynamic_target = TestSubject.new('003','dynamic_subject','dynamic_type')
        @dynamic = DynamicSubject.new(@dynamic_target)
        @seed = TestSeed.new('004','seed_subject','seed_type',@single,[@many_one,@many_two],@dynamic,1)
        @event = ExampleEvent.new(:seed=>@seed)
      end

      should 'find subjects with a 1 to 1 relationship' do
        assert_subject(@single,'single')
      end

      should 'find subjects with a 1 to many relationship' do
        assert_subject(@many_one,'many')
        assert_subject(@many_two,'many')
      end

      should 'find subjects with a block relationship' do
        assert_subject(@dynamic_target,'block')
      end

      should 'find the seed subject' do
        assert_subject(@seed,'seed')
      end

      should 'have five subjects in total' do
        # Just to make sure we're not registering extra subjects
        assert_equal 5, @event.subjects.length
      end
    end
  end
end
