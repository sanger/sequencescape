
require_relative '../../test_helper'

class StyleTest < ActiveSupport::TestCase

  attr_reader :style, :workbook

  def setup
  	@workbook = Axlsx::Package.new.workbook
    @style = SampleManifestExcel::Style.new(workbook, {locked: false})
  end
 
  test "should have options" do
  	refute style.options[:locked]
  end

  test "should have reference number" do
    assert workbook.styles.cellXfs[style.reference]
  end

end