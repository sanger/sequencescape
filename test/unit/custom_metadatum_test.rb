require 'test_helper'

class CustomMetadatumTest < ActiveSupport::TestCase
  test 'should not be valid if value is blank' do
    refute build(:custom_metadatum, value: nil).valid?
  end

  test 'should not allow duplicate keys for assets' do
    metadatum = create(:custom_metadatum)
    refute build(:custom_metadatum, key: metadatum.key, custom_metadatum_collection: metadatum.custom_metadatum_collection).valid?
  end

  test '#to_h should return the key and the value' do
    metadatum = create(:custom_metadatum, key: 'Key1', value: 'Value1')
    assert_equal({ 'Key1' => 'Value1' }, metadatum.to_h)
  end
end
