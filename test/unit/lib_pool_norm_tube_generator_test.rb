require "test_helper"

class LibPoolNormTubeGeneratorTest < ActiveSupport::TestCase

  attr_reader :plate, :user

  def valid_plate
    plate = create(:plate_with_wells)
    plate.plate_purpose.stubs(:name).returns("Lib PCR-XP")
    plate.stubs(:state).returns("qc_complete")
    plate
  end
  
  def setup
    @plate = valid_plate
    @user = create(:admin)
  end

  test "should not be valid without a valid plate barcode" do
    plate = create(:plate)
    assert LibPoolNormTubeGenerator.new(plate.ean13_barcode, user).plate.present?
    refute LibPoolNormTubeGenerator.new(plate, user).plate.present?
  end

  test "should not be valid without a user" do
    plate = create(:plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, nil).user.present?
  end

  test "should not be valid unless the state of the plate is qc complete" do
    plate = create(:plate)
    plate.plate_purpose.stubs(:name).returns("Lib PCR-XP")
    Plate.stubs(:find_from_machine_barcode).returns(plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, user).valid?
  end

  test "should not be valid unless the plate is a Lib PCR-XP plate" do
    plate = create(:plate)
    plate.stubs(:state).returns("qc_complete")
    Plate.stubs(:find_from_machine_barcode).returns(plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, user).valid?
  end

  context "with a valid plate" do

    attr_reader :plate, :transfer_template

    setup do
      @plate = valid_plate
      Plate.stubs(:find_from_machine_barcode).returns(plate)
    end

    should "be valid" do
      assert LibPoolNormTubeGenerator.new(plate.ean13_barcode, user).valid?
    end

    should "lib pool tubes should have the correct number" do
      generator = LibPoolNormTubeGenerator.new(plate.ean13_barcode, user)
      refute generator.lib_pool_tubes.empty?
      assert_equal generator.plate.wells.length, generator.lib_pool_tubes.length
    end

    should "have a transfer template" do
      generator = LibPoolNormTubeGenerator.new(plate.ean13_barcode, user)
      assert generator.transfer_template.present?
    end

    should "create all of the destination tubes with a state of qc complete" do
      transfer = mock("transfer")
      transfer.stubs(:destination).returns(create(:empty_sample_tube))
      generator = LibPoolNormTubeGenerator.new(plate.ean13_barcode, user)
      generator.transfer_template.stubs(:create!).returns(transfer)
      generator.create!
      refute generator.destination_tubes.empty?
      assert_equal generator.destination_tubes.length, generator.lib_pool_tubes.length
      assert generator.destination_tubes.all? { |dt| dt.state == "qc_complete" }
    end
  end

end
