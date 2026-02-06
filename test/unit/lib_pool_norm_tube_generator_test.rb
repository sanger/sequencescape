# frozen_string_literal: true

require 'test_helper'

class LibPoolNormTubeGeneratorTest < ActiveSupport::TestCase
  attr_reader :plate, :user, :study

  def valid_plate
    plate = create(:lib_pcr_xp_plate_with_tubes)
    plate.plate_purpose.stubs(:name).returns('Lib PCR-XP')
    plate.stubs(:state).returns('qc_complete')
    plate
  end

  def setup
    @user = create(:admin)
    @study = create(:study)
    create(:between_tubes_transfer_template) # Needed by LibPoolNormTubeGenerator.new
  end

  def mock_transfer(generator)
    generator.lib_pool_tubes.each do |source|
      transfer = mock('transfer')
      transfer.stubs(:destination).returns(create(:lib_pool_norm_tube, parent_tube: source))
      generator.transfer_template.stubs(:create!).with(user: @user, source: source).returns(transfer)
    end
  end

  test 'should not be valid without a valid plate barcode' do
    assert_not LibPoolNormTubeGenerator.new('dodgy barcode', user, study).valid?
  end

  test 'should not be valid without a user' do
    plate = valid_plate
    Plate.stubs(:with_barcode).returns(Plate.where(id: plate.id))

    assert_not LibPoolNormTubeGenerator.new(plate.ean13_barcode, nil, study).valid?
  end

  test 'should not be valid without a study' do
    plate = valid_plate
    Plate.stubs(:with_barcode).returns(Plate.where(id: plate.id))

    assert_not LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, nil).valid?
  end

  test 'should not be valid unless the state of the plate is qc complete' do
    plate = create(:lib_pcr_xp_plate_with_tubes)

    assert_not LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study).valid?
  end

  test 'should not be valid unless the plate is a Lib PCR-XP plate' do
    plate = create(:plate)
    plate.stubs(:state).returns('qc_complete')
    Plate.stubs(:with_barcode).returns(Plate.where(id: plate.id))

    assert_not LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study).valid?
  end

  context 'with a valid plate' do
    attr_reader :plate, :transfer_template, :generator

    setup do
      @plate = valid_plate
      Plate.stubs(:with_barcode).returns(Plate.where(id: plate.id))
      @generator = LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study)
      generator.stubs(:plate).returns(valid_plate)
    end

    should 'be valid, lib pool tubes should have the correct number, have a transfer template' do
      assert_predicate generator, :valid?
      assert_not generator.lib_pool_tubes.empty?
      assert_equal generator.plate.wells.length, generator.lib_pool_tubes.length
      assert_predicate generator.transfer_template, :present?
    end

    # rubocop:todo Layout/LineLength
    should 'set the state of the lib pool tubes to qc complete, create all of the destination tubes with a state of qc complete, create an asset group which includes all of the destination tubes' do
      # rubocop:enable Layout/LineLength
      generator.stubs(:lib_pool_tubes).returns(create_list(:lib_pool_tube, 3))
      mock_transfer(generator)

      assert generator.create!
      assert generator.lib_pool_tubes.all? { |lpt| lpt.reload.state == 'qc_complete' },
             "States were: #{generator.lib_pool_tubes.map(&:state)}"
      assert_not generator.destination_tubes.empty?
      assert_equal generator.lib_pool_tubes.length, generator.destination_tubes.length
      assert generator.destination_tubes.all? { |dt| dt.reload.state == 'qc_complete' },
             "States were: #{generator.destination_tubes.map(&:state)}"
      assert_predicate generator.asset_group, :present?
      assert_equal generator.destination_tubes.length, generator.asset_group.assets.length
    end
  end
end
