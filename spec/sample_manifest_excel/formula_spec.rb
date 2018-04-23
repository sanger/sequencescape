# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Download, type: :model, sample_manifest_excel: true do
  let(:references) { build(:range).references }
  let(:options) { { type: :smooth, operator: '>', operand: 30 } }
  let(:formula) { SampleManifestExcel::Formula.new(options) }

  it 'produces the correct output for the ISTEXT formula' do
    expect(formula.update(references.merge(type: :is_text)).to_s).to eq("ISTEXT(#{references[:first_cell_reference]})")
  end

  it 'should producue the correct output for the ISNUMBER formula' do
    expect(formula.update(references.merge(type: :is_number)).to_s).to eq("ISNUMBER(#{references[:first_cell_reference]})")
  end

  it 'should produce the correct output for the LEN formula' do
    expect(formula.update(references.merge(type: :len, operator: '>', operand: 999)).to_s).to eq("LEN(#{references[:first_cell_reference]})>999")
    expect(formula.update(references.merge(type: :len, operator: '<', operand: 999)).to_s).to eq("LEN(#{references[:first_cell_reference]})<999")
  end

  it 'should produce the correct output for the ISERROR formula' do
    expect(formula.update(references.merge(type: :is_error, operator: '>', operand: 999)).to_s).to eq("AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))")
  end

  it 'should produce the correct output irrespective of the format of type' do
    expect(formula.update(references.merge(type: 'is_error', operator: '>', operand: 999)).to_s).to eq("AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))")
  end

  it 'should be comparable' do
    expect(SampleManifestExcel::Formula.new(options)).to eq(formula)
    expect(SampleManifestExcel::Formula.new(options.except(:operand).merge(references.slice(:first_cell_reference)))).to_not eq(formula)
  end
end
