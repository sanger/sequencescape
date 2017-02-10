require 'test/unit'
require File.dirname(__FILE__) + '/../lib/acts_as_descriptable'
require File.join(File.dirname(__FILE__), 'test_helper')

class ActsAsDescriptableTest < Test::Unit::TestCase
  def teardown
    Post.all.each do |post|
      post.destroy
    end

    ActivePost.all.each do |post|
      post.destroy
    end
  end

  def test_descriptor_serialization
    post = Post.new
    hash = { field_1: 'test_controller', field_2: 'test_action' }
    array = [:field_1, :field_2]
    post.descriptors = hash
    post.descriptor_fields = array
    post.save
    retrieve_post = Post.first
    descriptors = retrieve_post.descriptors
    assert_kind_of Descriptor, descriptors[0]
    assert_equal :field_1, descriptors[0].name
    assert_equal 'test_controller', descriptors[0].value
    assert_equal :field_2, descriptors[1].name
    assert_equal 'test_action', descriptors[1].value
    assert_equal array, retrieve_post.descriptor_fields
  end

  def test_add_descriptor
    post = Post.new
    assert_equal 0, post.descriptors.size
    descriptor = Descriptor.new(name: 'test_name', value: 'test_value')
    post.add_descriptor descriptor
    assert_equal 1, post.descriptors.size
    assert_equal 'test_name', post.descriptors[0].name
    assert_equal 'test_value', post.descriptors[0].value
  end

  def test_add_multiple_descriptors
    post = Post.new
    assert_equal 0, post.descriptors.size
    descriptor = Descriptor.new(name: 'test_name', value: 'test_value')
    post.add_descriptor descriptor
    assert_equal 1, post.descriptors.size
    descriptor = Descriptor.new(name: 'test_name_2', value: 'test_value_2')
    post.add_descriptor descriptor
    assert_equal 2, post.descriptors.size
    descriptor = Descriptor.new(name: 'test_name_3', value: 'test_value_3')
    post.add_descriptor descriptor
    assert_equal 3, post.descriptors.size
    descriptor = Descriptor.new(name: 'test_name_4', value: 'test_value_4')
    post.add_descriptor descriptor
    assert_equal 4, post.descriptors.size
    assert_equal 'test_name', post.descriptors[0].name
    assert_equal 'test_value', post.descriptors[0].value

    assert_equal 'test_name_2', post.descriptors[1].name
    assert_equal 'test_value_2', post.descriptors[1].value

    assert_equal 'test_name_3', post.descriptors[2].name
    assert_equal 'test_value_3', post.descriptors[2].value

    assert_equal 'test_name_4', post.descriptors[3].name
    assert_equal 'test_value_4', post.descriptors[3].value
  end

  def test_active_descriptors
    post = ActivePost.new
    assert_equal 0, post.descriptors.size
    post.descriptors << Descriptor.new(name: 'test_value', value: 'test_value')
    assert_equal 1, post.descriptors.size
    post.descriptors << Descriptor.new(name: 'test_value2', value: 'test_value2')
    assert_equal 2, post.descriptors.size
  end

  def test_active_descriptors_create
    post = ActivePost.new
    params = { 0 => { name: 'test_name', value: 'test_value' },
               1 => { name: 'test_name1', value: 'test_value1' }
              }
    post.create_descriptors(params)
    assert_equal 2, post.descriptors.size
    descriptor = post.descriptors.first
    assert_kind_of Descriptor, descriptor
    assert_equal 'test_name', descriptor.name
    assert_equal 'test_value', descriptor.value

    descriptor = post.descriptors[1]
    assert_kind_of Descriptor, descriptor
    assert_equal 'test_name1', descriptor.name
    assert_equal 'test_value1', descriptor.value
  end

  def test_active_descriptors_sort
    post = ActivePost.new
    params = {
                5 => { name: 'test_name_e', value: 'test_value_e' },
                4 => { name: 'test_name_d', value: 'test_value_d' },
                3 => { name: 'test_name_c', value: 'test_value_c' },
                2 => { name: 'test_name_b', value: 'test_value_b' },
                1 => { name: 'test_name_a', value: 'test_value_a' },
              }
    post.create_descriptors(params)
    assert_equal 5, post.descriptors.size
    assert_equal 'test_name_a', post.descriptors[0].name
    assert_equal 'test_name_b', post.descriptors[1].name
    assert_equal 'test_name_c', post.descriptors[2].name
    assert_equal 'test_name_d', post.descriptors[3].name
    assert_equal 'test_name_e', post.descriptors[4].name
  end

  def test_active_descriptors_update
    post = ActivePost.new
    params = { 0 => { name: 'test_name', value: 'test_value' },
               1 => { name: 'test_name1', value: 'test_value1' }
              }
    post.create_descriptors(params)
    assert_equal 2, post.descriptors.size
    params = { 0 => { name: 'another_name', value: 'another_value' },
               1 => { name: 'another_name1', value: 'another_value1' },
               2 => { name: 'another_name2', value: 'another_value2' }
              }
    post.update_descriptors(params)
    assert_equal 3, post.descriptors.size
  end

  def test_active_descriptors_remove
    post = ActivePost.new
    params = { 0 => { name: 'test_name', value: 'test_value' },
               1 => { name: 'test_name1', value: 'test_value1' }
              }
    post.create_descriptors(params)
    post.save
    assert_equal 2, post.descriptors.size
    post.delete_descriptors
    assert_equal 0, post.descriptors.size
    assert_equal 0, Descriptor.count
  end

  def test_descriptor_xml
    post = Post.new
    hash = { controller: 'test_controller', action: 'test_action' }
    array = [:controller, :action]
    post.descriptors = hash
    post.descriptor_fields = array
    xml = post.descriptor_xml
    assert_equal '<?xml version="1.0" encoding="UTF-8"?><descriptors><descriptor><name>controller</name><value>test_controller</value></descriptor><descriptor><name>action</name><value>test_action</value></descriptor></descriptors>', xml
  end
end
