# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Cell, type: :model, sample_manifest_excel: true do
  it 'creates a row' do
    expect(SequencescapeExcel::Cell.new(1, 4).row).to eq(1)
  end

  it 'creates a column' do
    expect(SequencescapeExcel::Cell.new(1, 1).column).to eq('A')
    expect(SequencescapeExcel::Cell.new(1, 4).column).to eq('D')
    expect(SequencescapeExcel::Cell.new(1, 53).column).to eq('BA')
  end

  it 'creates a reference' do
    expect(SequencescapeExcel::Cell.new(150, 53).reference).to eq('BA150')
  end

  it 'creates a fixed reference' do
    expect(SequencescapeExcel::Cell.new(150, 53).fixed).to eq('$BA$150')
  end

  it 'is comparable' do
    expect(SequencescapeExcel::Cell.new(1, 1)).to eq(SequencescapeExcel::Cell.new(1, 1))
    expect(SequencescapeExcel::Cell.new(1, 1)).not_to eq(SequencescapeExcel::Cell.new(2, 1))
  end
end
