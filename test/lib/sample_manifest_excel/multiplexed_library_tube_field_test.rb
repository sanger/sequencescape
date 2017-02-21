require 'test_helper'

class MultiplexedLibraryTubeFieldTest < ActiveSupport::TestCase
  attr_reader :column_list, :tag_groups, :tag_group_cache

  def setup
    @tag_groups = create_list(:tag_group_with_tags, 5)
    @tag_group_cache = SampleManifestExcel::MultiplexedLibraryTubeField::TagGroupCache.new
    @column_list = build(:column_list_for_multiplexed_library_tube)
    create(:library_type, name: column_list.find_by(:name, :library_type).value)
    column_list.column_values(tag_group: tag_groups.first.name, tag_index: tag_groups.first.tags.first.map_id,
                              tag2_group: tag_groups.first.name, tag2_index: tag_groups.first.tags.first.map_id)
  end

  test 'should be a multiplexed library tube field' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new.multiplexed_library_tube_field?
  end

  test 'should have a list of subclasses' do
    assert_equal SampleManifestExcel::MultiplexedLibraryTubeField::Base.subclasses.count, SampleManifestExcel::MultiplexedLibraryTubeField::Base.fields.count
    assert_equal SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup, SampleManifestExcel::MultiplexedLibraryTubeField::Base.fields[:tag_group]
  end

  test 'update with cache should add it if the field requires it' do
    field = SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new
    assert_equal tag_group_cache, field.update(tag_group_cache: tag_group_cache).tag_group_cache
  end

  test 'update with links to other specialised fields should add them if required' do
    tag_index = SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new
    tag2_index = SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Index.new
    links = { tag_index: tag_index, tag2_index: tag2_index }

    assert_equal tag_index, SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(links).tag_index
    assert_equal tag2_index, SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Group.new.update(links).tag_index
  end

  test 'tag group cache should return the correct tag group' do
    tag_groups = create_list(:tag_group, 5)
    cache = SampleManifestExcel::MultiplexedLibraryTubeField::TagGroupCache.new
    assert_equal tag_groups.first, cache.find(tag_groups.first.name)
    assert_equal tag_groups.last, cache.find(tag_groups.last.name)
    refute cache.find(build(:tag_group))
  end

  test 'should not be valid if tag index is not in the row' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new.update(row: build(:row_for_plate, data: column_list.column_values(tag_index: nil), columns: column_list)).valid?
  end

  test 'should be no good if library type is not in the row' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values(library_type: nil), columns: column_list)).valid?
  end

  test 'should be no good if library type does not exist' do
    refute SampleManifestExcel::MultiplexedLibraryTubeField::LibraryType.new.update(row: build(:row_for_plate, data: column_list.column_values(library_type: build(:library_type)), columns: column_list)).valid?
  end

  test 'should be no good if insert size from is not in the row' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: nil), columns: column_list)).valid?
  end

  test 'should be no good if insert size from is not a number greater than zero' do
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: 0), columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeFrom.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_from: 'zero'), columns: column_list)).valid?
  end

  test 'should be no good if insert size to is not in the row' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: nil), columns: column_list)).valid?
  end

  test 'should be no good if insert size to is not a number greater than zero' do
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: 0), columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::InsertSizeTo.new.update(row: build(:row_for_plate, data: column_list.column_values(insert_size_to: 'zero'), columns: column_list)).valid?
  end

  test 'should be no good if tag group is not in the row' do
    assert SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(row: build(:row_for_plate, data: column_list.column_values, columns: column_list)).valid?
    refute SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(row: build(:row_for_plate, data: column_list.column_values(tag_group: nil), columns: column_list)).valid?
  end

  test 'should be no good if tag group does not exist' do
    refute SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(row: build(:row_for_plate, data: column_list.column_values(tag_group: build(:tag_group).name), columns: column_list), tag_group_cache: tag_group_cache).valid?
  end

  test 'should be no good if tag index is not an index within the tag group' do
    row = build(:row_for_plate, data: column_list.column_values, columns: column_list)
    tag_index = SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new.update(row: row)
    field = SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(row: row, tag_index: tag_index, tag_group_cache: tag_group_cache)
    assert field.valid?

    row = build(:row_for_plate, data: column_list.column_values(tag_index: build(:tag).map_id), columns: column_list)
    tag_index = SampleManifestExcel::MultiplexedLibraryTubeField::TagIndex.new.update(row: row)
    field = SampleManifestExcel::MultiplexedLibraryTubeField::TagGroup.new.update(row: row, tag_index: tag_index, tag_group_cache: tag_group_cache)
    refute field.valid?
    assert field.errors.key?(:tag_index)
  end

  test 'should be no good if tag2 group does not exist' do
    refute SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Group.new.update(row: build(:row_for_plate, data: column_list.column_values(tag2_group: build(:tag_group).name), columns: column_list), tag_group_cache: tag_group_cache).valid?
  end

  test 'should be no good if tag2 index is not an index within the tag2 group' do
    row = build(:row_for_plate, data: column_list.column_values, columns: column_list)
    tag2_index = SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Index.new.update(row: row)
    field = SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Group.new.update(row: row, tag2_index: tag2_index, tag_group_cache: tag_group_cache)
    assert field.valid?

    row = build(:row_for_plate, data: column_list.column_values(tag2_index: build(:tag).map_id), columns: column_list)
    tag2_index = SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Index.new.update(row: row)
    field = SampleManifestExcel::MultiplexedLibraryTubeField::Tag2Group.new.update(row: row, tag2_index: tag2_index, tag_group_cache: tag_group_cache)
    refute field.valid?
    assert field.errors.key?(:tag_index)
  end
end
