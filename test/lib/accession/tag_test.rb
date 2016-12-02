require 'test_helper'

class TagTest < ActiveSupport::TestCase

  def setup
  end

  test "should only be valid with a name and a parent" do
    assert Accession::Tag.new(name: :tag_1, parent: "name").valid?
    refute Accession::Tag.new(name: :tag_1).valid?
    refute Accession::Tag.new(parent: "name").valid?
  end

  test "should indicate which services it is required for" do
    tag = Accession::Tag.new(services: :ENA)
    assert tag.required_for?(:ENA)
    refute tag.required_for?(:EGA)

    tag = Accession::Tag.new(services: [:ENA, :EGA])
    assert tag.required_for?(:ENA)
    assert tag.required_for?(:EGA)

    tag = Accession::Tag.new
    refute tag.required_for?(:ENA)
    refute tag.required_for?(:EGA)
  end

  test "should indicate whether it is an array express field" do
    assert Accession::Tag.new(array_express: true).array_express?
    refute Accession::Tag.new.array_express?
  end

  test "should be able to add a value" do
    assert_equal "Value 1", Accession::Tag.new(value: "Value 1").value
    assert_equal "Value 2", Accession::Tag.new.add_value("Value 2").value
  end
    
end