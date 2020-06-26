# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::List, type: :model, sample_manifest_excel: true, sample_manifest: true do
  class ListItem
    attr_reader :attr_a, :attr_b, :attr_c, :attr_d

    def initialize(attr_a, attr_b, attr_c, attr_d, valid = true)
      @attr_a = attr_a
      @attr_b = attr_b
      @attr_c = attr_c
      @attr_d = attr_d
      @valid = valid
    end

    def valid?
      @valid
    end
  end

  class MyList
    include SequencescapeExcel::List
    list_for :list_items, keys: %i[attr_a attr_b attr_c]
  end

  let(:item_1) { ListItem.new('a', 'b', 'c', 'd') }
  let(:item_2) { ListItem.new('e', 'f', 'g', 'h') }
  let(:item_3) { ListItem.new('i', 'j', 'k', 'l') }
  let(:item_4) { ListItem.new('m', 'n', 'o', 'p', false) }
  let(:my_list) do
    MyList.new do |list|
      list.add item_1
      list.add item_2
      list.add item_3
      list.add item_4
    end
  end

  it 'has the correct number of items' do
    expect(my_list.count).to eq(3)
    expect(my_list.list_items.count).to eq(3)
  end

  it 'each key has the correct number of items' do # rubocop:todo RSpec/AggregateExamples
    expect(my_list.items.attr_a.count).to eq(3)
    expect(my_list.items.attr_b.count).to eq(3)
    expect(my_list.items.attr_c.count).to eq(3)
  end

  it 'is possible to find an item by a defined key' do
    expect(my_list.find_by(:attr_a, 'a')).to eq(item_1)
    expect(my_list.find_by(:attr_b, 'f')).to eq(item_2)
    expect(my_list.find_by(:attr_b, :f)).to eq(item_2)
    expect(my_list.find_by(:attr_c, 'k')).to eq(item_3)
  end

  it 'is possible to find an attribute using any key' do
    expect(my_list.find('a')).to eq(item_1)
    expect(my_list.find('f')).to eq(item_2)
    expect(my_list.find(:f)).to eq(item_2)
    expect(my_list.find('k')).to eq(item_3)
    expect(my_list.find('z')).to be_nil
  end

  it '#reset should create a new list of items' do
    items = my_list.items
    my_list.reset!
    expect(my_list.values).to be_empty
    expect(my_list.items).not_to eq(items)
    expect(my_list.items.attr_a).to be_empty
    expect(my_list.items.attr_b).to be_empty
    expect(my_list.items.attr_c).to be_empty
  end

  it 'each key should pull back the attributes for that key' do # rubocop:todo RSpec/AggregateExamples
    expect(my_list.attr_as).to eq(%w[a e i])
    expect(my_list.attr_bs).to eq(%w[b f j])
    expect(my_list.attr_cs).to eq(%w[c g k])
  end

  it 'copy adds a copy of the object to the list' do
    item = ListItem.new('q', 'r', 's', 't')
    my_list.add_copy item
    expect(my_list.find_by(:attr_a, 'q')).not_to eq(item)
  end

  it 'is comparable' do
    expect(my_list).not_to be_nil
    other_list = MyList.new
    other_list.add item_1
    other_list.add item_2
    other_list.add item_3
    other_list.add item_4
    expect(other_list).to eq(my_list)
  end
end
