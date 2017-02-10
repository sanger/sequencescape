# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class MessengerTest < ActiveSupport::TestCase
  context '#Messenger' do
    setup do
      @target    = Batch.new
      # @target.stubs(:class).returns(Batch)
      @template  = 'FlowcellIO'
      @messenger = Messenger.new(target: @target, template: @template, root: 'example')
    end

    context 'to_json' do
      setup do
        Api::Messages::FlowcellIO.expects(:to_hash).with(@target).returns('example' => 'hash')
      end

      should 'render the json' do
        assert_equal '{"example":{"example":"hash"},"lims":"SQSCP"}', @messenger.to_json
      end
    end

    should 'provide a routing key' do
      assert_equal @messenger.routing_key, "test.message.example.#{@messenger.id}"
    end
  end
end
