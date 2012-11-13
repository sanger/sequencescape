require 'test_helper'

class Core::Io::Json::GrammarTest < ActiveSupport::TestCase
  context Core::Io::Json::Grammar::Leaf do
    context 'nested attribute value' do
      setup do
        @target = Core::Io::Json::Grammar::Leaf.new(:attribute_name, ['root', 'leaf'])
        @object, @stream = mock('Target object'), mock('Stream')
      end

      teardown do
        @target.call(@object, :options, @stream)
      end

      should 'not stream nil intermediate values' do
        @object.expects(:root).returns(nil)
      end

      should 'stream nested attribute value' do
        @object.expects(:root).returns(OpenStruct.new(:leaf => 'value'))
        @stream.expects(:attribute).with(:attribute_name, 'value', :options)
      end
    end

    should 'stream simple attribute value' do
      target = Core::Io::Json::Grammar::Leaf.new(:attribute_name, ['leaf'])
      stream = mock('Stream')
      stream.expects(:attribute).with(:attribute_name, 'value', :options)
      target.call(OpenStruct.new(:leaf => 'value'), :options, stream)
    end
  end

  context Core::Io::Json::Grammar::Node do
    should 'implement the Intermediate module' do
      assert(Core::Io::Json::Grammar::Node.included_modules.include?(Core::Io::Json::Grammar::Intermediate))
    end

    should 'place children inside a block' do
      stream, nested_stream = mock('Stream'), mock('Nested Stream')
      stream.expects(:block).with(:attribute_name).yields(nested_stream)

      children = Hash[[ 'Child 1', 'Child 2' ].map do |name|
        child = mock(name).tap { |child| child.expects(:call).with(:object, :options, nested_stream) }
        [name, child]
      end]

      target = Core::Io::Json::Grammar::Node.new(:attribute_name, children)
      target.call(:object, :options, stream)
    end
  end

  context Core::Io::Json::Grammar::Root do
    should 'implement the Intermediate module' do
      assert(Core::Io::Json::Grammar::Root.included_modules.include?(Core::Io::Json::Grammar::Intermediate))
    end

    context 'with object' do
      setup do
        @object  = OpenStruct.new(:created_at => 'now', :updated_at => 'tomorrow')
        @handler = mock('Handler')
      end

      teardown do
        stream, nested_stream = mock('Stream'), mock('Nested Stream')
        stream.expects(:block).with(:root_json).yields(nested_stream)
        nested_stream.expects(:attribute).with('created_at', 'now')
        nested_stream.expects(:attribute).with('updated_at', 'tomorrow')

        options  = { :handled_by => @handler }

        children = Hash[[ 'Child 1', 'Child 2' ].map do |name|
          child = mock(name).tap { |child| child.expects(:call).with(@object, options, nested_stream) }
          [name, child]
        end]
        target = Core::Io::Json::Grammar::Root.new(OpenStruct.new(:json_root => :root_json), children)
        target.call(@object, options, stream)
      end

      should 'nest children within a block' do
        # Nothing needed in here at the moment
      end

      should 'attempt lookup of action handling' do
        @object.stubs(:uuid).returns(:object_uuid)
        @handler.expects(:endpoint_for_object, @object).raises(Core::Endpoint::BasicHandler::EndpointLookup::MissingEndpoint)
      end
    end
  end
end
