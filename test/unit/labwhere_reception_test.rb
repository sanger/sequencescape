require 'test_helper'

class LabwhereReceptionTest < ActiveSupport::TestCase
  MockResponse = Struct.new(:valid?, :error)

  attr_reader :user, :plate_1, :plate_2, :labware_barcodes_in_ss, :labware_barcodes_not_in_ss, :labware_barcodes_both

  def setup
    @user = create(:user, barcode: 'ID123', swipecard_code: '02face')
    @plate_1 = create(:plate, barcode: 1)
    @plate_2 = create(:plate, barcode: 2)
    @labware_barcodes_in_ss = [plate_1.ean13_barcode, plate_2.ean13_barcode]
    @labware_barcodes_not_in_ss = ['1', '11111111111111']
    @labware_barcodes_both = [plate_1.ean13_barcode, '22', '222222222222222']
  end

  test 'it should scan the labware into the location' do
    LabWhereClient::Scan.expects(:create).with(
      location_barcode: 'labwhere_location', user_code: user.barcode, labware_barcodes: labware_barcodes_in_ss
    ).returns(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', labware_barcodes_in_ss)
    assert labwhere_reception.save
  end

  test 'it should scan the labware into the location if the labware is not in ss' do
    LabWhereClient::Scan.expects(:create).with(
      location_barcode: 'labwhere_location', user_code: user.barcode, labware_barcodes: labware_barcodes_not_in_ss
    ).returns(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', labware_barcodes_not_in_ss)
    assert_equal true, labwhere_reception.save
  end

  test 'it should scan the labware into the location if labware is or is not in ss' do
    LabWhereClient::Scan.expects(:create).with(
      location_barcode: 'labwhere_location', user_code: user.barcode, labware_barcodes: labware_barcodes_both
    ).returns(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', labware_barcodes_both)
    assert_equal true, labwhere_reception.save
  end

  test 'it should not scan the labware into the location if no user supplied' do
    LabWhereClient::Scan.stubs(:create).returns(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new('', 'labwhere_location', labware_barcodes_in_ss)
    assert_equal false, labwhere_reception.save
    assert_equal 1, labwhere_reception.errors.count
  end

  test 'it should not scan the labware into the location if no barcodes scanned' do
    LabWhereClient::Scan.stubs(:create).returns(MockResponse.new(true, ''))
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', [])
    assert_equal false, labwhere_reception.save
    assert_equal 1, labwhere_reception.errors.count
  end

  test 'it should not scan the labware into the location if scan was not created' do
    LabWhereClient::Scan.expects(:create).returns(MockResponse.new(false, ''))
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', labware_barcodes_in_ss)
    assert_equal false, labwhere_reception.save
  end

  test 'it should not scan the labware into the location if LabwhereException was raised' do
    LabWhereClient::Scan.expects(:create).raises(LabWhereClient::LabwhereException)
    labwhere_reception = LabwhereReception.new(user.barcode, 'labwhere_location', labware_barcodes_in_ss)
    assert_equal false, labwhere_reception.save
    assert_equal 1, labwhere_reception.errors.count
  end
end
