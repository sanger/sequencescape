# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Download, type: :model, sample_manifest_excel: true, sample_manifest: true do
  let(:references) { build(:range).references }
  let(:options) { { type: :smooth, operator: '>', operand: 30 } }
  let(:formula) { SequencescapeExcel::Formula.new(options) }

  it 'produces the correct output for the ISTEXT formula' do
    expect(formula.update(references.merge(type: :is_text)).to_s).to eq("ISTEXT(#{references[:first_cell_reference]})")
  end

  it 'producues the correct output for the ISNUMBER formula' do # rubocop:todo RSpec/AggregateExamples
    expect(formula.update(references.merge(type: :is_number)).to_s).to eq("ISNUMBER(#{references[:first_cell_reference]})")
  end

  it 'produces the correct output for the LEN formula' do # rubocop:todo RSpec/AggregateExamples
    expect(formula.update(references.merge(type: :len, operator: '>', operand: 999)).to_s).to eq("LEN(#{references[:first_cell_reference]})>999")
    expect(formula.update(references.merge(type: :len, operator: '<', operand: 999)).to_s).to eq("LEN(#{references[:first_cell_reference]})<999")
  end

  it 'produces the correct output for the ISERROR formula' do # rubocop:todo RSpec/AggregateExamples
    expect(formula.update(references.merge(type: :is_error, operator: '>',
                                           operand: 999)).to_s).to eq("AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))")
  end

  it 'produces the correct output irrespective of the format of type' do # rubocop:todo RSpec/AggregateExamples
    expect(formula.update(references.merge(type: 'is_error', operator: '>',
                                           operand: 999)).to_s).to eq("AND(NOT(ISBLANK(#{references[:first_cell_reference]})),ISERROR(MATCH(#{references[:first_cell_reference]},#{references[:absolute_reference]},0)>0))")
  end

  it 'is comparable' do
    expect(SequencescapeExcel::Formula.new(options)).to eq(formula)
    expect(SequencescapeExcel::Formula.new(options.except(:operand).merge(references.slice(:first_cell_reference)))).not_to eq(formula)
  end
end
