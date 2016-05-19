module SampleManifestExcel
  class Cell

    include Comparable

    attr_reader :row, :column

    def initialize(x, y)
      @row = x
      @column = to_alpha(y)
    end

    def reference
      @reference ||= "#{column}#{row}"
    end

    def fixed
      @fixed ||= "$#{column}$#{row}"
    end

    def <=>(other)
      row <=> other.row && column <=> other.column
    end

  private

    def to_alpha(n)
      (n-1)<26 ? ((n-1)%26+65).chr : ((n-1)/26+64).chr + ((n-1)%26+65).chr
    end
    
  end
end