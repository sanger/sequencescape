require 'test_helper'

class SpecialisedFieldsTest < ActiveSupport::TestCase

  attr_reader :column_list, :tag_groups, :tag_group_cache

  def setup
    @tag_groups = create_list(:tag_group_with_tags, 5)
    @tag_group_cache = SampleManifestExcel::SpecialisedFields::TagGroupCache.new
    @column_list = build(:column_list_for_multiplexed_library_tube)
    create(:library_type, name: column_list.find_by(:name, :library_type).value)
    column_list.column_values(tag_group: tag_groups.first.name, tag_index: tag_groups.first.tags.first.map_id)
  end

  test "should have a key" do
    field = SampleManifestExcel::SpecialisedFields::TagIndex.new
    assert_equal :tag_index, field.key
  end

  test "should update attributes" do
    field = SampleManifestExcel::SpecialisedFields::TagGroup.new
    field.update_attributes(tag_index: 10, tag_group_cache: tag_group_cache)
    assert_equal 10, field.tag_index
    assert_equal tag_group_cache, field.tag_group_cache
  end

  test "tag group cache should return the correct tag group" do
    tag_groups = create_list(:tag_group, 5)
    cache = SampleManifestExcel::SpecialisedFields::TagGroupCache.new
    assert_equal tag_groups.first, cache.find(tag_groups.first.name)
    assert_equal tag_groups.last, cache.find(tag_groups.last.name)
    refute cache.find(build(:tag_group))
  end

  test "should be no good if tag index is not in the row" do
    field = SampleManifestExcel::SpecialisedFields::TagIndex.new
    assert field.good?(build(:row, data: column_list.column_values, columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(tag_index: nil), columns: column_list))
  end

  test "should be no good if library type is not in the row" do
    field = SampleManifestExcel::SpecialisedFields::LibraryType.new
    assert field.good?(build(:row, data: column_list.column_values, columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(library_type: nil), columns: column_list))
  end

  test "should be no good if library type does not exist" do
    field = SampleManifestExcel::SpecialisedFields::LibraryType.new
    refute field.good?(build(:row, data: column_list.column_values(library_type: build(:library_type)), columns: column_list))
  end

  test "should be no good if insert size from is not in the row" do
    field = SampleManifestExcel::SpecialisedFields::InsertSizeFrom.new
    assert field.good?(build(:row, data: column_list.column_values, columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(insert_size_from: nil), columns: column_list))
  end

  test "should be no good if insert size from is not a number greater than zero" do
    field = SampleManifestExcel::SpecialisedFields::InsertSizeFrom.new
    refute field.good?(build(:row, data: column_list.column_values(insert_size_from: 0), columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(insert_size_from: "zero"), columns: column_list))
  end

  test "should be no good if insert size to is not in the row" do
    field = SampleManifestExcel::SpecialisedFields::InsertSizeTo.new
    assert field.good?(build(:row, data: column_list.column_values, columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(insert_size_to: nil), columns: column_list))
  end

  test "should be no good if insert size to is not a number greater than zero" do
    field = SampleManifestExcel::SpecialisedFields::InsertSizeTo.new
    refute field.good?(build(:row, data: column_list.column_values(insert_size_to: 0), columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(insert_size_to: "zero"), columns: column_list))
  end

  test "should be no good if tag group is not in the row" do
    field = SampleManifestExcel::SpecialisedFields::TagGroup.new
    assert field.good?(build(:row, data: column_list.column_values, columns: column_list))
    refute field.good?(build(:row, data: column_list.column_values(tag_group: nil), columns: column_list))
  end

  test "should be no good if tag group does not exist" do
    field = SampleManifestExcel::SpecialisedFields::TagGroup.new
    field.update_attributes(tag_group_cache: tag_group_cache)
    refute field.good?(build(:row, data: column_list.column_values(tag_group: build(:tag_group).name), columns: column_list))
  end

  test "should be no good if tag index is not an index within the tag group" do
    field = SampleManifestExcel::SpecialisedFields::TagGroup.new
    field.update_attributes(tag_group_cache: tag_group_cache, tag_index: build(:tag).map_id)
    refute field.good?(build(:row, data: column_list.column_values(tag_index: build(:tag).map_id), columns: column_list))
  end

  test "should be no good if tag2 group does not exist" do
    field = SampleManifestExcel::SpecialisedFields::Tag2Group.new
    field.update_attributes(tag_group_cache: tag_group_cache)
    refute field.good?(build(:row, data: column_list.column_values(tag2_group: build(:tag_group).name), columns: column_list))
  end

end