require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helper')

class ActsAsDescriptableTest < Test::Unit::TestCase
    
  def teardown
    Descriptor.find(:all).each { |descriptor| descriptor.destroy }
  end
  
  def test_descriptor
    descriptor = Descriptor.new
    descriptor.name = "name"
    descriptor.value = "value"
    descriptor.save
    retrieved_descriptor = Descriptor.find(:first)
    assert_equal "name", retrieved_descriptor.name
    assert_equal "value", retrieved_descriptor.value
  end
  
end
