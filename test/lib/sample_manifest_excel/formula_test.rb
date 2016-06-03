require_relative '../../test_helper'

class FormulaTest < ActiveSupport::TestCase

  attr_reader :formula, :options

  def setup
    @options = {type: :nice, operator: :gt, operand: 30, first_cell: 'A1', absolute_reference: "A1:A5"}
    @formula = SampleManifestExcel::Formula.new(options)
  end

  test "should produce the correct output for the ISTEXT formula" do
    assert_equal "ISTEXT(A1)", formula.update(type: :is_text, first_cell: "A1", absolute_reference: "$A$4:$B$639").to_s
  end

  test "should producue the correct output for the ISNUMBER formula" do
    assert_equal "ISNUMBER(A1)", formula.update(type: :is_number, first_cell: "A1", absolute_reference: "$A$4:$B$639").to_s
  end


  test "should produce the correct output for the LEN formula" do
    assert_equal "LEN(A10)>999", formula.update(type: :len, first_cell: "A10", operator: :gt, operand: 999).to_s
    assert_equal "LEN(A10)<999", formula.update(type: :len, first_cell: "A10", operator: :lt, operand: 999).to_s
  end

  test "should produce the correc output for the ISERROR formula" do
    assert_equal "ISERROR(MATCH(A10,Ranges!$A$4:$B$639,0)>0)", formula.update(type: :is_error, first_cell: "A10", absolute_reference: "Ranges!$A$4:$B$639", operator: ">", operand: 999).to_s
  end

  test "should be comparable" do
    assert_equal formula, SampleManifestExcel::Formula.new(options)
    refute_equal formula, SampleManifestExcel::Formula.new(options.except(:operand).merge(first_cell: "A10"))
  end

end