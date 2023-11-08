# frozen_string_literal: true

# Helper class that wraps well ranges in specs
class WellRange
  WELL_REGEXP = /^([A-H])(\d+)$/

  def initialize(start, finish)
    start_match = WELL_REGEXP.match(start)
    finish_match = WELL_REGEXP.match(finish)
    @rows = (start_match[1]..finish_match[1])
    @columns = (start_match[2].to_i..finish_match[2].to_i)
  end

  def include?(well)
    include_well_location?(well.map.description)
  end

  def to_a
    [].tap do |wells|
      (1..12).each do |column|
        ('A'..'H').each do |row|
          well = "#{row}#{column}"
          wells << well if include_well_location?(well)
        end
      end
    end
  end

  delegate :size, to: :to_a

  private

  def include_well_location?(location)
    well_match = WELL_REGEXP.match(location)
    @rows.include?(well_match[1]) && @columns.include?(well_match[2].to_i)
  end
end
