require "test_helper"

class BarcodeLabelTest < ActiveSupport::TestCase

  context "A barcode label" do
    should_have_instance_methods :number, :study, :suffix
    should_have_instance_methods :number=, :study=, :suffix=

      context "with no prefix" do
        context "and with a LE#study" do
          setup do
            @label = BarcodeLabel.new(:study =>"LEstudy")
          end

          should "use the study for prefix" do
            assert_equal "LE", @label.barcode_prefix("default")
          end
        end
        context "and without a LE#study" do
          setup do
            @label = BarcodeLabel.new(:study =>"study")
          end

          should "use the default prefix" do
            assert_equal "default", @label.barcode_prefix("default")
          end
        end
    end

  end


end
