require 'test_helper'

class ColumnTest < ActiveSupport::TestCase

  attr_reader :column

  context "basic" do
    setup do
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME")
    end

    should "have a heading" do
      assert_equal column.heading, "PUBLIC NAME"
    end

    should "have a position" do
      assert_equal column.position, 0
      column.position = 10
      assert_equal column.position, 10
    end

    should "have no validation" do
      refute column.has_validation?
    end

    should "have no attribute" do
      refute column.has_attribute?
    end
  end

  context "with attribute" do
    setup do
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", attribute: :public_name)
    end

    should "have an attribute" do
      assert_equal :public_name, column.attribute
      assert column.has_attribute?
    end
  end

  context "with validation" do
    setup do
      @column = SampleManifestExcel::Column.new(heading: "PUBLIC NAME", validation: true)
    end

    should "have some validation" do
      assert column.validation
      assert column.has_validation?
    end
  end

end