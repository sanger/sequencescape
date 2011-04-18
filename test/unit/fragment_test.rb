require "test_helper"

class FragmentTest < ActiveSupport::TestCase
  context Fragment do
    context '#to_xml' do
      setup do
        @fragment = Factory(:fragment)
      end

      should 'not fail if descriptor_fields present' do
        @fragment.add_descriptor(Descriptor.new(:name => 'descriptor', :value => 'value'))
        @fragment.to_xml.inspect
      end
    end
  end
end
