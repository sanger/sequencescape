# frozen_string_literal: true

module LabelPrinterTests
  module SharedTubeTests
    # rubocop:todo Metrics/MethodLength

    def self.included(base) # rubocop:todo Metrics/AbcSize
      base.class_eval do
        test 'should return the correct values' do
          assert_equal (barcode1).to_s, tube_label.second_line(tube1)
          assert_equal prefix, tube_label.round_label_top_line(tube1)
          assert_equal barcode1, tube_label.round_label_bottom_line(tube1)
          assert_match barcode1, tube_label.barcode(tube1)
        end

        test 'should return the correct label' do
          assert_equal label, tube_label.build_label(tube1)
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end

  module SharedPlateTests
    def self.included(base) # rubocop:todo Metrics/AbcSize
      base.class_eval do
        test 'should return correct common values' do
          assert_match barcode1, plate_label.bottom_left(plate1)
          assert_match barcode1, plate_label.barcode(plate1)
        end

        test 'should return the correct label' do
          assert_equal label, plate_label.build_label(plate1)
        end
      end
    end
  end
end
