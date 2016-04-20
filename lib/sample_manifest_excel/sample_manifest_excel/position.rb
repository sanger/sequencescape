module SampleManifestExcel
  
  class Position

    attr_accessor :first_column, :last_column, :first_row, :last_row
    attr_reader :reference

    def initialize(attributes={})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
      @reference = create_reference
    end

    private

    # turn number into characters for excel
    # examples:
    # - if number is 0 return nil
    # - if number is less than 26 return single character e.g. 1 = "A", 26 = "Z"
    # - if number is greater than 26 return two characters e.g. 27 = "AA"

    def to_alpha(n)
      (n-1)<26 ? ((n-1)%26+65).chr : ((n-1)/26+64).chr + ((n-1)%26+65).chr
    end

    def create_reference
      if last_column.present?
        _create_reference(first_column, first_row, last_column, first_row)
      else
        _create_reference(first_column, first_row, first_column, last_row)
      end
    end

    def _create_reference(first_column, first_row, last_column, last_row)
      "$#{to_alpha(first_column)}$#{first_row}:$#{to_alpha(last_column)}$#{last_row}"
    end

  end

end