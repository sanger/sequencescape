# frozen_string_literal: true

require 'test_helper'
require_relative 'shared_tests'

class PlateCreatorTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedPlateTests

  attr_reader :plate_label,
              :plate1,
              :plates,
              :plate_purpose,
              :label,
              :user,
              :barcode1,
              :parent_barcode,
              :study_abbreviation,
              :purpose_name

  def setup # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @parent_barcode = 'SQPD-1234'
    @studies = create_list :study, 1
    parent = create :source_plate, barcode: parent_barcode, studies: @studies
    well = create :well_with_sample_and_plate, plate: parent
    @barcode1 = 'SQPD-1111'
    @purpose_name = 'test purpose'
    plate_purpose = create :plate_purpose, name: purpose_name
    @plate1 =
      create :child_plate,
             parent:,
             barcode: barcode1,
             plate_purpose:,
             well_count: 1,
             well_factory: :untagged_well,
             studies: @studies
    @plates = [plate1]
    @user = 'user'
    @study_abbreviation = 'WTCCC'
    options = { plate_purpose:, plates:, user_login: user }
    @plate_label = LabelPrinter::Label::PlateCreator.new(options)
    @label = {
      top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
      bottom_left: (plate1.human_barcode).to_s,
      top_right: (purpose_name).to_s,
      bottom_right: "#{user} #{study_abbreviation}",
      top_far_right: (parent_barcode).to_s,
      barcode: plate1.machine_barcode,
      label_name: 'main_label'
    }
  end

  test 'should have plates' do
    assert_equal plates, plate_label.assets
  end

  test 'should return the correct specific values' do
    assert_equal purpose_name, plate_label.top_right(plate1)
    assert_equal "#{user} #{study_abbreviation}", plate_label.bottom_right(plate1)
    assert_equal (parent_barcode).to_s, plate_label.top_far_right(plate1)
  end
end
