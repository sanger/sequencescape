require 'test_helper'

class ListTest < ActiveSupport::TestCase

  class ListItem
    attr_reader :attr_a, :attr_b, :attr_c, :attr_d
    def initialize(attr_a,attr_b,attr_c,attr_d,valid=true)
      @attr_a, @attr_b, @attr_c, @attr_d, @valid = attr_a,attr_b,attr_c,attr_d,valid
    end
    def valid?
      @valid
    end
  end

  class MyList
    include SampleManifestExcel::List
    list_for :list_items, keys: [:attr_a, :attr_b, :attr_c]
  end

  attr_reader :item_1, :item_2, :item_3, :item_4, :my_list

  def setup
    @item_1 = ListItem.new("a","b","c","d")
    @item_2 = ListItem.new("e","f","g","h")
    @item_3 = ListItem.new("i","j","k","l")
    @item_4 = ListItem.new("m","n","o","p",false)
    @my_list = MyList.new
    my_list.add item_1
    my_list.add item_2
    my_list.add item_3
    my_list.add item_4
  end

  test "list should have correct number of items" do
    assert_equal 3, my_list.count
    assert_equal 3, my_list.list_items.count
  end

  test "each key should have the correct number of items" do
    assert_equal 3, my_list.items.attr_a.count
    assert_equal 3, my_list.items.attr_b.count
    assert_equal 3, my_list.items.attr_c.count
  end

  test "it should be possible to find an item by a defined key" do
    assert_equal item_1, my_list.find_by(:attr_a, "a")
    assert_equal item_2, my_list.find_by(:attr_b, "f")
    assert_equal item_2, my_list.find_by(:attr_b, :f)
    assert_equal item_3, my_list.find_by(:attr_c, "k")
  end

  test "it should be possible to find an attribute using any key" do
    assert_equal item_1, my_list.find("a")
    assert_equal item_2, my_list.find("f")
    assert_equal item_2, my_list.find(:f)
    assert_equal item_3, my_list.find("k")
    refute my_list.find("z")
  end

  test "#reset should create a new list of items" do
    items = my_list.items
    my_list.reset!
    assert my_list.values.empty?
    refute_equal items, my_list.items
    assert my_list.items.attr_a.empty?
    assert my_list.items.attr_b.empty?
    assert my_list.items.attr_c.empty?
  end

  test "each key should pull back the attributes for that key" do
    assert_equal ["a","e","i"], my_list.attr_as
    assert_equal ["b","f","j"], my_list.attr_bs
    assert_equal ["c","g","k"], my_list.attr_cs
  end

  test "copy should add a copy of the object to the list" do
    item = ListItem.new("q","r","s","t")
    my_list.add_copy item
    refute_equal item, my_list.find_by(:attr_a, "q")
  end

  test "should be comparable" do
    refute_equal my_list, nil
    other_list = MyList.new
    other_list.add item_1
    other_list.add item_2
    other_list.add item_3
    other_list.add item_4
    assert_equal my_list, other_list
  end
end