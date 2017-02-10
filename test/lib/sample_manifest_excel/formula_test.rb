require 'test_helper'

class FormulaTest < ActiveSupport::TestCase
  attr_reader :formula, :options, :references

  def setup
    @references = build(:range).references
    @options = { type: :smooth, operator: '>', operand: 30 }
    @formula = SampleManifestExcel::Formula.new(options)
  end

  test 'should produce the correct output for the ISTEXT formula' do
    assert_equal "ISTEXT(#{references[:first_cell_reference]})", formula.update(references.merge(type: :is_text)).to_s
  end

  test 'should producue the correct output for the ISNUMBER formula' do
    assert_equal "ISNUMBER(#{references[:first_cell_reference]})", formula.update(references.merge(type: :is_number)).to_s
  end

  test 'should produce the correct output for the LEN formula' do
    assert_equal "LEN(#{references[:first_cell_reference]})>999", formula.update(references.merge(type: :len, operator: '>', operand: 999)).to_s
    assert_equal "LEN(#{references[:first_cell_reference]})<999", formula.update(references.merge(type: :len, operator: '<', operand: 999)).to_s
  end

  test 'should produce the correct output for the ISERROR formula' do
    assert_equal "AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))", formula.update(references.merge(type: :is_error, operator: '>', operand: 999)).to_s
  end

  test 'should produce the correct output irrespective of the format of type' do
    assert_equal "AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))", formula.update(references.merge(type: 'is_error', operator: '>', operand: 999)).to_s
  end

  test 'should be comparable' do
    assert_equal formula, SampleManifestExcel::Formula.new(options)
    refute_equal formula, SampleManifestExcel::Formula.new(options.except(:operand).merge(references.slice(:first_cell_reference)))
  end
end
