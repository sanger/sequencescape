# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2014,2015 Genome Research Ltd.

require 'test_helper'

class AmqpObserverTest < ActiveSupport::TestCase
  OWNED_CLASSES = { WellAttribute => :well, Metadata::Base => :owner }

  class AmqpObserver
    attr_accessor :mock_exchange
    include ::AmqpObserver::Implementation
  end

  def return_from_inside_transaction(target, object)
    target.transaction do
      target << object
      return
    end
  end

  context AmqpObserver do
    setup do
      @target = AmqpObserver.new.tap do |target|
        def target.activate_exchange
          yield(mock_exchange)
        end
      end
    end

    context '#publish' do
      should 'send the JSON message appropriately' do
        object, object_class = mock('Object being broadcast'), mock('Class of object being broadcast')
        object.stubs(:id).returns(123456789)
        object.stubs(:class).returns(object_class)
        object.expects(:to_json).returns('JSON')
        object.stubs(:routing_key).returns(nil)
        object_class.stubs(:name).returns('ClassName')

        @exchange = mock('Exchange for sending')
        @exchange.expects(:publish).with('JSON', routing_key: 'test.saved.class_name.123456789', persistent: false)
        @target.instance_variable_set(:@mock_exchange, @exchange)

        @target.send(:publish_to, @exchange, object)
      end
    end

    context '#<<' do
      context 'outside transaction' do
        should 'send multiple messages for updates to an object' do
          object = mock('Object to broadcast')
          object.stubs(:destroyed?).returns(false)
          @target.expects(:publish_to).with(@exchange, object).twice

          @target << object << object
        end

        should 'send both the creation and the deletion message' do
          object = mock('Object to broadcast')
          object.expects(:destroyed?).twice.returns(false, true)
          @target.expects(:publish_to).with(@exchange, object).twice

          @target << object << object
        end

        OWNED_CLASSES.each do |base_class, owner|
          should "does not send if #{base_class.name} is being destroyed" do
            object, metadata = mock('Object to broadcast'), mock("#{base_class.name} being destroyed")
            metadata.stubs(:destroyed?).returns(true)
            metadata.stubs(owner).returns(object)
            OWNED_CLASSES.each { |c, _| metadata.stubs(:is_a?).with(c).returns(base_class == c) }
            metadata.stubs(:is_a?).with(Role).returns(false)

            @target << metadata
          end
        end

        context 'role related' do
          setup do
            @object, @role = mock('Object to broadcast'), mock('Role being updated')

            @role.stubs(:destroyed?).returns(false)
            OWNED_CLASSES.each { |c, _| @role.stubs(:is_a?).with(c).returns(false) }
            @role.stubs(:is_a?).with(Role).returns(true)
            @role.stubs(:authorizable).returns(@object)

            OWNED_CLASSES.each { |c, _| @object.stubs(:is_a?).with(c).returns(false) }
            @object.stubs(:is_a?).with(Role).returns(false)
            @object.stubs(:is_a?).with(Role::UserRole).returns(false)

            @target.expects(:publish_to).with(@exchange, @object).once
          end

          should 'send the authorized record for roles' do
            @target << @role
          end

          should 'send the authorized record for a user role addition' do
            user_role = mock('User role being added')

            user_role.stubs(:destroyed?).returns(false)
            OWNED_CLASSES.each { |c, _| user_role.stubs(:is_a?).with(c).returns(false) }
            user_role.stubs(:is_a?).with(Role).returns(false)
            user_role.stubs(:is_a?).with(Role::UserRole).returns(true)
            user_role.stubs(:role).returns(@role)

            @target << user_role
          end
        end
      end

      context 'inside transaction' do
        should 'broadcast even in the presence of return' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)
          object_class.expects(:unscoped).yields
          object_class.expects(:find).with([object.id]).returns([object])
          @target.expects(:publish_to).with(@exchange, object).once
          return_from_inside_transaction(@target, object)
        end

        should 'no message on exceptions' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)

          begin
            @target.transaction do
              @target << object
              raise StandardError, 'Do not send thanks!'
            end
          rescue StandardError => exception
            nil
          end
        end

        should 'only send one copy of the object' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)
          object_class.expects(:unscoped).yields
          object_class.expects(:find).with([object.id]).returns([object])
          @target.expects(:publish_to).with(@exchange, object).once

          @target.transaction do
            @target << object << object
          end
        end

        should 'send only send the deletion message' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.expects(:destroyed?).twice.returns(false, true)
          @target.expects(:publish_to).with(@exchange, object).once

          @target.transaction do
            @target << object << object
          end
        end

        should 'only send messages at the close of the outside transaction' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)
          object_class.expects(:unscoped).yields
          object_class.expects(:find).with([object.id]).returns([object])

          # NOTE: Expectation set after the inner transaction so that it will error if the method
          # is called by that inner transaction
          @target.transaction do
            @target.transaction { @target << object }
            @target.expects(:publish_to).with(@exchange, object).once
          end
        end

        OWNED_CLASSES.each do |base_class, owner|
          should "does not send if #{base_class.name} is being destroyed" do
            object, object_class, metadata = mock('Object to broadcast'), mock('Class of object to broadcast'), mock("#{base_class.name} being destroyed")
            object.stubs(:id).returns(123456789)
            object.stubs(:class).returns(object_class)
            metadata.stubs(:destroyed?).returns(true)
            metadata.stubs(owner).returns(object)
            OWNED_CLASSES.each { |c, _| metadata.stubs(:is_a?).with(c).returns(base_class == c) }

            @target.transaction do
              @target << metadata
            end
          end
        end
      end
    end
  end
end
