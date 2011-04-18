require "test_helper"

class BarcodeLabelTest < ActiveSupport::TestCase

  context "A barcode label" do
    should_have_instance_methods :number, :study, :suffix
    should_have_instance_methods :number=, :study=, :suffix=
  end

end
