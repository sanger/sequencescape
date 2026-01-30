# frozen_string_literal: true

require 'test_helper'

# Structs for configatron stub
AmqpStruct = Struct.new(:lims_id!, keyword_init: true)
ConfigatronStruct = Struct.new(:amqp, keyword_init: true)

class MessengerTest < ActiveSupport::TestCase
  context '#Messenger' do
    setup do
      @target = Batch.new
      @template = 'FlowcellIo'
      @messenger = Messenger.new(target: @target, template: @template, root: 'example')
    end

    context 'to_json' do
      setup do
        Api::Messages::FlowcellIo.expects(:to_hash).with(@target).returns('example' => 'hash')
        # Stub configatron for lims_id! using Struct (defined at top)
        amqp = AmqpStruct.new(lims_id!: 'SQSCP')
        configatron = ConfigatronStruct.new(amqp:)
        @messenger.stubs(:configatron).returns(configatron)
        # Stub process_receptacles to pass through message
        @messenger.stubs(:process_receptacles).returns('example' => 'hash')
        Rails.logger.stubs(:info)
      end

      should 'render the json' do
        assert_equal '{"example":{"example":"hash"},"lims":"SQSCP"}', @messenger.to_json
      end

      should 'render the json when template is historical (ends in IO)' do
        messenger = Messenger.new(target: @target, template: 'FlowcellIO', root: 'example')
        amqp = AmqpStruct.new(lims_id!: 'SQSCP')
        configatron = ConfigatronStruct.new(amqp:)
        messenger.stubs(:configatron).returns(configatron)
        messenger.stubs(:process_receptacles).returns('example' => 'hash')
        Rails.logger.stubs(:info)
        assert_equal '{"example":{"example":"hash"},"lims":"SQSCP"}', messenger.to_json
      end
    end

    context '#process_receptacles' do
      setup do
        @message = { 'foo' => 'bar' }
      end

      should 'return message unchanged if not a receptacle target' do
        @messenger.stubs(:receptacle_target?).returns(false)
        assert_equal @message, @messenger.process_receptacles(@message.dup)
      end

      should 'add labware_type if asset_type is library_plate' do
        @messenger.stubs(:receptacle_target?).returns(true)
        @messenger.stubs(:fetch_asset_type).returns('library_plate')
        result = @messenger.process_receptacles(@message.dup)
        assert_equal 'library_plate_well', result['labware_type']
      end

      should 'not add labware_type if asset_type is not library_plate' do
        @messenger.stubs(:receptacle_target?).returns(true)
        @messenger.stubs(:fetch_asset_type).returns('other_type')
        result = @messenger.process_receptacles(@message.dup)
        assert_nil result['labware_type']
      end
    end

    should 'provide a routing key' do
      assert_equal @messenger.routing_key, "message.example.#{@messenger.id}"
    end
  end
end
