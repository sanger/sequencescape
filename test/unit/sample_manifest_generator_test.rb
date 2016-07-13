require "test_helper"

class SampleManifestGeneratorTest < ActiveSupport::TestCase

  attr_reader :generator, :attributes, :study, :supplier, :user

  def stub_barcode_service
    barcode = mock("barcode")
    barcode.stubs(:barcode).returns(23)
    PlateBarcode.stubs(:create).returns(barcode)
  end

  def setup
    @user = create(:user)
    @study = create(:study)
    @supplier = create(:supplier)
    @attributes = { "template": "full_plate", "study_id": study.id, "supplier_id": supplier.id,
                    "count": "4", "barcode_printer": "41", "only_first_label": "1", 
                    "asset_type": "plate"}.with_indifferent_access
    stub_barcode_service
  end

  test "should not be valid without a user" do
    @generator = SampleManifestGenerator.new(attributes, nil)
    refute generator.valid?
  end

  test "should create a sample manifest" do
    @generator = SampleManifestGenerator.new(attributes, user)
    generator.execute
    assert_equal study.id, generator.sample_manifest.study_id
    refute generator.sample_manifest.new_record?
  end

  test "should raise an error if sample manifest is not valid" do
    assert_raises ActiveRecord::RecordInvalid do
      SampleManifestGenerator.new(attributes.except(:study_id), user).execute
    end
  end

  test "should generate sample manifest to create samples" do
    @generator = SampleManifestGenerator.new(attributes, user)
    generator.execute
    refute generator.sample_manifest.details_array.empty?
  end
  
end