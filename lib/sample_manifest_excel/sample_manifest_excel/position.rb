module SampleManifestExcel
  
  module Position

    def set_position(position)
      self.position = position
      self
    end

    # turn number into characters for excel
    # examples:
    # - if number is 0 return nil
    # - if number is less than 26 return single character e.g. 1 = "A", 26 = "Z"
    # - if number is greater than 26 return two characters e.g. 27 = "AA"

    def to_alpha(n)
      (n-1)<26 ? ((n-1)%26+65).chr : ((n-1)/26+64).chr + ((n-1)%26+65).chr
    end

  end

end