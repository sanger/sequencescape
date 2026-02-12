# frozen_string_literal: true

require 'test_helper'

class MessengerTest < ActiveSupport::TestCase
  context '#Messenger' do
    setup do
      @target = Batch.new

      # @target.stubs(:class).returns(Batch)
      @template = 'FlowcellIo'
      @messenger = Messenger.new(target: @target, template: @template, root: 'example')
    end

    context 'to_json' do
      setup { Api::Messages::FlowcellIo.expects(:to_hash).with(@target).returns('example' => 'hash') }

      should 'render the json' do
        assert_equal '{"example":{"example":"hash"},"lims":"SQSCP"}', @messenger.to_json
      end

      should 'render the json when template is historical (ends in IO)' do
        messenger = Messenger.new(target: @target, template: 'FlowcellIO', root: 'example')

        assert_equal '{"example":{"example":"hash"},"lims":"SQSCP"}', messenger.to_json
      end
    end

    should 'provide a routing key' do
      assert_equal @messenger.routing_key, "message.example.#{@messenger.id}"
    end
  end
end
