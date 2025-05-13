# frozen_string_literal: true

require 'rails_helper'

class TestSeed
  include ActiveModel::Model
  include ActiveModel::AttributeMethods
  define_attribute_methods :uuid,
                           :friendly_name,
                           :subject_type,
                           :single_relation,
                           :many_relation,
                           :dynamic_relation,
                           :id,
                           :data_method_a

  attr_accessor :uuid,
                :friendly_name,
                :subject_type,
                :single_relation,
                :many_relation,
                :dynamic_relation,
                :id,
                :data_method_a,
                :nil_relation

  def self.primary_key
    :id
  end

  def self.has_query_constraints?
    false
  end

  def self.composite_primary_key?
    false
  end

  def self.polymorphic_name
    'TestSeed'
  end

  def attributes
    {
      'uuid' => @uuid,
      'friendly_name' => @friendly_name,
      'subject_type' => @subject_type,
      'single_relation' => @single_relation,
      'nil_relation' => @nil_relation,
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

# As BroadcastEvents is primarily about making events easy to configure
# lets generate a test instance
class ExampleEvent < BroadcastEvent
  set_event_type 'example_event'

  seed_class TestSeed

  # The seed itself can be a subject
  seed_subject :seed

  # Methods that yield a single object
  has_subject :single, :single_relation

  # Methods that yield a single object (that can be nil)
  has_subject :nil, :nil_relation

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

RSpec.describe BroadcastEvent, :broadcast_event do
  it 'is not directly instantiated' do
    expect(described_class.new).not_to be_valid
  end

  describe 'ExampleEvent' do
    it 'is instantiated' do
      expect(ExampleEvent.new).to be_present
    end

    context 'with a seed' do
      let(:single) { TestSubject.new('000', 'single_subject', 'single_type') }
      let(:many_one) { TestSubject.new('001', 'many_subject_1', 'many_type') }
      let(:many_two) { TestSubject.new('002', 'many_subject_2', 'many_type') }
      let(:dynamic_target) { TestSubject.new('003', 'dynamic_subject', 'dynamic_type') }
      let(:value_b) { 'value_b' }
      let(:dynamic) { DynamicSubject.new(dynamic_target, value_b) }
      let(:value_a) { 'value_a' }
      let(:user) { create(:user, email: 'example@example.com') }
      let(:time) { Time.zone.parse('2012-03-11 10:22:42') }
      let(:seed) do
        TestSeed.new(
          uuid: '004',
          friendly_name: 'seed_subject',
          subject_type: 'seed_type',
          single_relation: single,
          many_relation: [many_one, many_two],
          dynamic_relation: dynamic,
          id: 1,
          data_method_a: value_a
        )
      end
      let(:event) { ExampleEvent.new(seed: seed, user: user, created_at: time) }

      it 'finds subjects with a 1 to 1 relationship' do
        expect(event.subjects).to be_present

        test_subject = event.subjects.detect { |s| s.uuid == single.uuid }

        expect(test_subject).to be_present
        expect(test_subject.friendly_name).to eq(single.friendly_name)
        expect(test_subject.subject_type).to eq(single.subject_type)
        expect(test_subject.role_type).to eq('single')
      end

      it 'has five subjects' do
        expect(event.subjects).to be_present
        expect(event.subjects.length).to eq(5)
      end

      it 'finds subjects with a 1 to many relationship' do
        test_subject = event.subjects.detect { |s| s.uuid == many_one.uuid }

        expect(test_subject).to be_present
        expect(test_subject.friendly_name).to eq(many_one.friendly_name)
        expect(test_subject.subject_type).to eq(many_one.subject_type)
        expect(test_subject.role_type).to eq('many')

        test_subject = event.subjects.detect { |s| s.uuid == many_two.uuid }

        expect(test_subject).to be_present
        expect(test_subject.friendly_name).to eq(many_two.friendly_name)
        expect(test_subject.subject_type).to eq(many_two.subject_type)
        expect(test_subject.role_type).to eq('many')
      end

      it 'finds subjects with a block relationship' do
        test_subject = event.subjects.detect { |s| s.uuid == dynamic_target.uuid }

        expect(test_subject).to be_present
        expect(test_subject.friendly_name).to eq(dynamic_target.friendly_name)
        expect(test_subject.subject_type).to eq(dynamic_target.subject_type)
        expect(test_subject.role_type).to eq('block')
      end

      it 'finds the seed subject' do
        test_subject = event.subjects.detect { |s| s.uuid == seed.uuid }

        expect(test_subject).to be_present
        expect(test_subject.friendly_name).to eq(seed.friendly_name)
        expect(test_subject.subject_type).to eq(seed.subject_type)
        expect(test_subject.role_type).to eq('seed')
      end

      it 'finds metadata by simple call' do
        expect(event.metadata['data_a']).to eq(value_a)
      end

      it 'finds metadata by block calls' do
        expect(event.metadata['data_b']).to eq(value_b)
      end

      it 'scopes metadata on event' do
        expect(event.metadata['data_c']).to eq('value_c')
      end

      it 'finds all metadata as a hash' do
        expect(event.metadata).to eq({ 'data_a' => value_a, 'data_b' => value_b, 'data_c' => 'value_c' })
      end

      describe '#routing_key' do
        it 'includes the event type and id' do
          expect(event.routing_key).to eq "event.example_event.#{event.id}"
        end
      end

      it 'generates the expected json' do
        event.save!

        expected_json = {
          'event' => {
            'uuid' => event.uuid,
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

        expect(JSON.parse(event.to_json)).to eq(expected_json)
      end
    end
  end
end
