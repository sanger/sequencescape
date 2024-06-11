# frozen_string_literal: true

class MockParser
  DEFAULT_MOCK_VALUES = {
    'B1' => {
      Concentration: Unit.new('2 ng/ul'),
      Molarity: Unit.new('3 nM'),
      Volume: Unit.new('20 ul'),
      RIN: Unit.new('6 RIN')
    },
    'C1' => {
      Concentration: Unit.new('4 ng/ul'),
      Molarity: Unit.new('5 nM'),
      Volume: Unit.new('20 ul'),
      RIN: Unit.new('6 RIN')
    }
  }.freeze
  def initialize(data = DEFAULT_MOCK_VALUES)
    @data = data
  end

  def assay_type
    'Mock parser'
  end

  def assay_version
    '1.0'
  end

  def each_well_and_parameters(&)
    @data.each(&)
  end
end
