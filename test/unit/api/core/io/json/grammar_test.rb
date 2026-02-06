# frozen_string_literal: true

require 'test_helper'

class Core::Io::Json::GrammarTest < ActiveSupport::TestCase
  context Core::Io::Json::Grammar::Leaf do
    context 'nested attribute value' do
      setup do
        @target = Core::Io::Json::Grammar::Leaf.new(:attribute_name, %w[root leaf])
        @object, @stream = mock('Target object'), mock('Stream')
      end

      teardown { @target.call(@object, :options, @stream) }

      should 'not stream nil intermediate values' do
        @object.expects(:root).returns(nil)
      end

      should 'stream nested attribute value' do
        @object.expects(:root).returns(OpenStruct.new(leaf: 'value')) # rubocop:todo Style/OpenStructUse
        @stream.expects(:attribute).with(:attribute_name, 'value', :options)
      end
    end

    should 'stream simple attribute value' do
      target = Core::Io::Json::Grammar::Leaf.new(:attribute_name, ['leaf'])
      stream = mock('Stream')
      stream.expects(:attribute).with(:attribute_name, 'value', :options)
      target.call(OpenStruct.new(leaf: 'value'), :options, stream) # rubocop:todo Style/OpenStructUse
    end
  end

  context Core::Io::Json::Grammar::Node do
    should 'implement the Intermediate module' do
      assert_includes(Core::Io::Json::Grammar::Node, Core::Io::Json::Grammar::Intermediate)
    end

    should 'place children inside a block' do
      stream, nested_stream = mock('Stream'), mock('Nested Stream')
      stream.expects(:block).with(:attribute_name).yields(nested_stream)

      children =
        ['Child 1', 'Child 2'].to_h do |name|
          child = mock(name).tap { |child| child.expects(:call).with(:object, :options, nested_stream) }
          [name, child]
        end

      target = Core::Io::Json::Grammar::Node.new(:attribute_name, children)
      target.call(:object, :options, stream)
    end
  end

  context Core::Io::Json::Grammar::Root do
    should 'implement the Intermediate module' do
      assert_includes(Core::Io::Json::Grammar::Root, Core::Io::Json::Grammar::Intermediate)
    end

    context 'with object' do
      setup do
        @object = OpenStruct.new(created_at: 'now', updated_at: 'tomorrow') # rubocop:todo Style/OpenStructUse
        @handler = mock('Handler')
      end

      teardown do
        stream, nested_stream = mock('Stream'), mock('Nested Stream')
        stream.expects(:block).with(:root_json).yields(nested_stream)
        nested_stream.expects(:attribute).with('created_at', 'now')
        nested_stream.expects(:attribute).with('updated_at', 'tomorrow')

        options = { handled_by: @handler }

        children =
          ['Child 1', 'Child 2'].to_h do |name|
            child = mock(name).tap { |child| child.expects(:call).with(@object, options, nested_stream) }
            [name, child]
          end
        target = Core::Io::Json::Grammar::Root.new(OpenStruct.new(json_root: :root_json), children) # rubocop:todo Style/OpenStructUse
        target.call(@object, options, stream)
      end
    end
  end
end
