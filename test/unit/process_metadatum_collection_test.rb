require 'test_helper'

class ProcessMetadatumCollectionTest < ActiveSupport::TestCase

  test "should not be valid without an asset" do 
    refute build(:process_metadatum_collection, asset: nil).valid?
  end

  test "should not be valid without a user" do
    refute build(:process_metadatum_collection, user: nil).valid?
  end

  test "should be able to create metadata" do
    process_metadatum_collection = create(:process_metadatum_collection, metadata: ({'Key1' => 'Value1', 'Key2' => 'Value2'}))
    assert_equal 2, process_metadatum_collection.process_metadata.length
    assert_equal 'Key1', process_metadatum_collection.process_metadata.first.key
  end

  test "should be able to create metadata and check if it is valid" do
    process_metadatum_collection = build(:process_metadatum_collection, metadata: ({'Key1' => 'Value1', 'Key2' => ''}))
    refute process_metadatum_collection.valid?
  end

  test "#metadata should return all of the metadata as a beautiful hash" do
    metadata = build_list(:process_metadatum, 2)
    process_metadatum_collection = create(:process_metadatum_collection, process_metadata: metadata)
    assert_equal metadata.first.to_h.merge(metadata.last.to_h), process_metadatum_collection.metadata
  end

  test "should update metadata" do
    process_metadatum_collection = create(:process_metadatum_collection, metadata: ({'Key1' => 'Value1', 'Key2' => 'Value2'}))
    process_metadatum_collection.update_attributes(metadata: {"Key1" => "New value", "Key3" => "Value3"})
    assert_equal 2, process_metadatum_collection.process_metadata.length
    assert_equal "New value", process_metadatum_collection.process_metadata.first.value
    assert_equal "Value3", process_metadatum_collection.process_metadata.last.value
  end
end
