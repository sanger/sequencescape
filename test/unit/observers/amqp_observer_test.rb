require 'test_helper'

class AmqpObserverTest < ActiveSupport::TestCase
  OWNED_CLASSES = { WellAttribute => :well, Metadata::Base => :owner }

  class AmqpObserver
    include ::AmqpObserver::Implementation
  end

  context AmqpObserver do
    setup do
      @target = AmqpObserver.new.tap do |target|
        def target.activate_exchange(&block)
          yield
        end
      end
    end

    context '#publish' do
      should 'send the JSON message appropriately' do
        object, object_class = mock('Object being broadcast'), mock('Class of object being broadcast')
        object.stubs(:id).returns(123456789)
        object.stubs(:class).returns(object_class)
        object.expects(:to_json).returns('JSON')
        object_class.stubs(:name).returns('ClassName')

        exchange = mock('Exchange for sending')
        exchange.expects(:publish).with('JSON', :key => 'test.saved.class_name.123456789', :persistent => false)
        @target.instance_variable_set(:@exchange, exchange)

        @target.send(:publish, object)
      end
    end

    context '#<<' do
      context 'outside transaction' do
        should 'send multiple messages for updates to an object' do
          object = mock('Object to broadcast')
          object.stubs(:destroyed?).returns(false)
          @target.expects(:publish).with(object).twice

          @target << object << object
        end

        should 'send both the creation and the deletion message' do
          object = mock('Object to broadcast')
          object.expects(:destroyed?).twice.returns(false, true)
          @target.expects(:publish).with(object).twice

          @target << object << object
        end

        OWNED_CLASSES.each do |base_class, owner|
          should "does not send if #{base_class.name} is being destroyed" do
            object, metadata = mock('Object to broadcast'), mock("#{base_class.name} being destroyed")
            metadata.stubs(:destroyed?).returns(true)
            metadata.stubs(owner).returns(object)
            OWNED_CLASSES.each { |c,_| metadata.stubs(:is_a?).with(c).returns(base_class == c) }

            @target << metadata
          end
        end
      end

      context 'inside transaction' do
        should 'only send one copy of the object' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)
          object_class.expects(:find).with([object.id]).returns([object])
          @target.expects(:publish).with(object).once

          @target.transaction do
            @target << object << object
          end
        end

        should 'send only send the deletion message' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.expects(:destroyed?).twice.returns(false, true)
          @target.expects(:publish).with(object).once

          @target.transaction do
            @target << object << object
          end
        end

        should 'only send messages at the close of the outside transaction' do
          object, object_class = mock('Object to broadcast'), mock('Class of object to broadcast')
          object.stubs(:id).returns(123456789)
          object.stubs(:class).returns(object_class)
          object.stubs(:destroyed?).returns(false)
          object_class.expects(:find).with([object.id]).returns([object])

          # NOTE: Expectation set after the inner transaction so that it will error if the method
          # is called by that inner transaction
          @target.transaction do
            @target.transaction { @target << object }
            @target.expects(:publish).with(object).once
          end
        end

        OWNED_CLASSES.each do |base_class, owner|
          should "does not send if #{base_class.name} is being destroyed" do
            object, object_class, metadata = mock('Object to broadcast'), mock('Class of object to broadcast'), mock("#{base_class.name} being destroyed")
            object.stubs(:id).returns(123456789)
            object.stubs(:class).returns(object_class)
            metadata.stubs(:destroyed?).returns(true)
            metadata.stubs(owner).returns(object)
            OWNED_CLASSES.each { |c,_| metadata.stubs(:is_a?).with(c).returns(base_class == c) }

            @target.transaction do
              @target << metadata
            end
          end
        end
      end
    end
  end
end
